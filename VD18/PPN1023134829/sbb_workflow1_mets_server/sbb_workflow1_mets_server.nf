nextflow.enable.dsl=2

// The values are assigned inside the batch script
// Based on internal values and options provided in the request
params.input_file_group = "null"
params.mets = "null"
params.mets_socket = "null"
params.workspace_dir = "null"
// amount of pages of the workspace
params.pages = "null"
params.singularity_wrapper = "null"
params.cpus = "null"
params.ram = "null"
params.forks = params.cpus
// Do not pass these parameters from the caller unless you know what you are doing
params.cpus_per_fork = (params.cpus.toInteger() / params.forks.toInteger()).intValue()
params.ram_per_fork = sprintf("%dGB", (params.ram.toInteger() / params.forks.toInteger()).intValue())

log.info """\
         O P E R A N D I - H P C - sbb_workflow1_mets_server
         ===========================================
         input_file_group    : ${params.input_file_group}
         mets                : ${params.mets}
         mets_socket         : ${params.mets_socket}
         workspace_dir       : ${params.workspace_dir}
         pages               : ${params.pages}
         singularity_wrapper : ${params.singularity_wrapper}
         cpus                : ${params.cpus}
         ram                 : ${params.ram}
         forks               : ${params.forks}
         cpus_per_fork       : ${params.cpus_per_fork}
         ram_per_fork        : ${params.ram_per_fork}
         """
         .stripIndent()

process split_page_ranges {
    maxForks params.forks
    cpus params.cpus_per_fork
    memory params.ram_per_fork
    debug true

    input:
        val range_multiplier
    output:
        env current_range_pages
    shell:
    '''
    current_range_pages=$(!{params.singularity_wrapper} ocrd workspace -d !{params.workspace_dir} list-page -f comma-separated -D !{params.forks} -C !{range_multiplier})
    echo "Current range is: $current_range_pages"
    '''
}

process ocrd_cis_ocropy_binarize {
    maxForks params.forks
    cpus params.cpus_per_fork
    memory params.ram_per_fork
    debug true

    input:
        val page_range
        val input_group
        val output_group
    output:
        val page_range

    script:
    """
    ${params.singularity_wrapper} ocrd-cis-ocropy-binarize -U ${params.mets_socket} -w ${params.workspace_dir} --page-id ${page_range} -m ${params.mets} -I ${input_group} -O ${output_group}
    """
}

process ocrd_tesserocr_segment {
    maxForks params.forks
    cpus params.cpus_per_fork
    memory params.ram_per_fork
    debug true

    input:
        val page_range
        val input_group
        val output_group
    output:
        val page_range

    script:
    """
    ${params.singularity_wrapper} ocrd-tesserocr-segment -U ${params.mets_socket} -w ${params.workspace_dir} --page-id ${page_range} -m ${params.mets} -I ${input_group} -O ${output_group}
    """
}

process ocrd_kraken_recognize {
    maxForks params.forks
    cpus params.cpus_per_fork
    memory params.ram_per_fork
    debug true

    input:
        val page_range
        val input_group
        val output_group
    output:
        val page_range

    script:
    """
    ${params.singularity_wrapper} ocrd-kraken-recognize -U ${params.mets_socket} -w ${params.workspace_dir} --page-id ${page_range} -m ${params.mets} -I ${input_group} -O ${output_group} -p '{"model": "typewriter.mlmodel"}'
    """
}

workflow {
  main:
    ch_range_multipliers = Channel.of(0..params.forks.intValue()-1)
    split_page_ranges(ch_range_multipliers)
    ocrd_cis_ocropy_binarize(split_page_ranges.out, params.input_file_group, "OCR-D-BIN")
    ocrd_tesserocr_segment(ocrd_cis_ocropy_binarize.out, "OCR-D-BIN", "OCR-D-SEG")
    ocrd_kraken_recognize(ocrd_tesserocr_segment.out, "OCR-D-SEG", "OCR-D-OCR")
}
