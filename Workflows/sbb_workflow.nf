// This workflow was automatically generated by the operandi_utils.oton module
nextflow.enable.dsl = 2

params.input_file_group = "OCR-D-IMG"
params.mets_path = "null"
params.workspace_dir = "null"
params.pages = "null"
params.cpus = "null"
params.ram = "null"
params.forks = params.cpus
params.cpus_per_fork = (params.cpus.toInteger() / params.forks.toInteger()).intValue()
params.ram_per_fork = sprintf("%dGB", (params.ram.toInteger() / params.forks.toInteger()).intValue())
params.env_wrapper_cmd_core = "null"
params.env_wrapper_cmd_step0 = "null"

log.info """\
    OPERANDI HPC - Nextflow Workflow
    ===================================================
    input_file_group: ${params.input_file_group}
    mets_path: ${params.mets_path}
    workspace_dir: ${params.workspace_dir}
    pages: ${params.pages}
    cpus: ${params.cpus}
    ram: ${params.ram}
    forks: ${params.forks}
    cpus_per_fork: ${params.cpus_per_fork}
    ram_per_fork: ${params.ram_per_fork}
    env_wrapper_cmd_core: ${params.env_wrapper_cmd_core}
    env_wrapper_cmd_step0: ${params.env_wrapper_cmd_step0}
    """.stripIndent()

process split_page_ranges {
    debug true
    maxForks params.forks
    cpus params.cpus_per_fork
    memory params.ram_per_fork

    input:
        val range_multiplier

    output:
        env mets_file_chunk
        env current_range_pages

    script:
        """
        current_range_pages=\$(${params.env_wrapper_cmd_core} ocrd workspace -d ${params.workspace_dir} list-page -f comma-separated -D ${params.forks} -C ${range_multiplier})
        echo "Current range is: \$current_range_pages"
        mets_file_chunk=\$(echo ${params.workspace_dir}/mets_${range_multiplier}.xml)
        echo "Mets file chunk path: \$mets_file_chunk"
        \$(${params.env_wrapper_cmd_core} cp -p ${params.mets_path} \$mets_file_chunk)
        """
}

process ocrd_tesserocr_recognize_0 {
    debug true
    maxForks params.forks
    cpus params.cpus_per_fork
    memory params.ram_per_fork

    input:
        val mets_path
        val page_range
        val input_group
        val output_group

    output:
        val mets_path
        val page_range

    script:
        """
        ${params.env_wrapper_cmd_step0} ocrd-tesserocr-recognize -w ${params.workspace_dir} -m ${mets_path} --page-id ${page_range} -I ${input_group} -O ${output_group} -p '{"segmentation_level": "region", "textequiv_level": "word", "find_tables": true, "model": "deu"}'
        """
}

process merging_mets {
    debug true
    maxForks 1
    cpus params.cpus_per_fork
    memory params.ram_per_fork

    input:
        val mets_file_chunk
        val page_range

    script:
        """
        ${params.env_wrapper_cmd_core} ocrd workspace -d ${params.workspace_dir} merge --force --no-copy-files ${mets_file_chunk} --page-id ${page_range}
        ${params.env_wrapper_cmd_core} rm ${mets_file_chunk}
        """
}

workflow {
    main:
        ch_range_multipliers = Channel.of(0..params.forks.intValue()-1)
        split_page_ranges(ch_range_multipliers)
        ocrd_tesserocr_recognize_0(split_page_ranges.out[0], split_page_ranges.out[1], params.input_file_group, "OCR-D-OCR")
        merging_mets(ocrd_tesserocr_recognize_0.out[0], ocrd_tesserocr_recognize_0.out[1])
}
