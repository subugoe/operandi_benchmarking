nextflow.enable.dsl=2

// The values are assigned inside the batch script
// Based on internal values and options provided in the request
params.input_file_group = "null"
params.mets = "null"
params.workspace_dir = "null"
params.singularity_wrapper = "null"
params.cpus = "null"
params.ram = "null"

log.info """\
        O P E R A N D I - H P C - sbb_workflow1
        ===========================================
        input_file_group    : ${params.input_file_group}
        mets                : ${params.mets}
        workspace_dir       : ${params.workspace_dir}
        singularity_wrapper : ${params.singularity_wrapper}
        cpus                : ${params.cpus}
        ram                 : ${params.ram}
        """
        .stripIndent()

process ocrd_olena_binarize {
    maxForks 1
    cpus params.cpus
    memory params.ram
    debug true

    input:
        path mets_file
        val input_group
        val output_group

    output:
        path mets_file

    script:
    """
    ${params.singularity_wrapper} ocrd-olena-binarize -w !{params.workspace_dir} -m ${mets_file} -I ${input_group} -O ${output_group}
    """
}

process ocrd_tesserocr_segment {
    maxForks 1
    cpus params.cpus
    memory params.ram
    debug true

    input:
        path mets_file
        val input_group
        val output_group

    output:
        path mets_file

    script:
    """
    ${params.singularity_wrapper} ocrd-tesserocr-segment -w !{params.workspace_dir} -m ${mets_file} -I ${input_group} -O ${output_group}
    """
}

process ocrd_kraken_recognize {
    maxForks 1
    cpus params.cpus
    memory params.ram
    debug true

    input:
        path mets_file
        val input_group
        val output_group

    output:
        path mets_file

    script:
    """
    ${params.singularity_wrapper} ocrd-kraken-recognize -w !{params.workspace_dir} -m ${mets_file} -I ${input_group} -O ${output_group} -p '{"model": "typewriter.mlmodel"}'
    """
}

workflow {
  main:
    ocrd_olena_binarize(params.mets, params.input_file_group, "OCR-D-BIN")
    ocrd_tesserocr_segment(ocrd_olena_binarize.out, "OCR-D-BIN", "OCR-D-SEG")
    ocrd_kraken_recognize(ocrd_tesserocr_segment.out, "OCR-D-SEG", "OCR-D-OCR")
}
