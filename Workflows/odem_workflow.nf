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
         O P E R A N D I - H P C - odem_workflow
         ===========================================
         input_file_group    : ${params.input_file_group}
         mets                : ${params.mets}
         workspace_dir       : ${params.workspace_dir}
         singularity_wrapper : ${params.singularity_wrapper}
         cpus                : ${params.cpus}
         ram                 : ${params.ram}
         """
         .stripIndent()

process ocrd_cis_ocropy_binarize_0 {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_dir
    val output_dir

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-cis-ocropy-binarize -w !{params.workspace_dir} -m ${mets_file} -I ${input_dir} -O ${output_dir} -P dpi 300
  """
}

process ocrd_anybaseocr_crop_1 {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_dir
    val output_dir

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-anybaseocr-crop -w !{params.workspace_dir} -m ${mets_file} -I ${input_dir} -O ${output_dir} -P dpi 300
  """
}

process ocrd_cis_ocropy_denoise_2 {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_dir
    val output_dir

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-cis-ocropy-denoise -w !{params.workspace_dir} -m ${mets_file} -I ${input_dir} -O ${output_dir} -P dpi 300
  """
}

process ocrd_cis_ocropy_deskew_3 {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_dir
    val output_dir

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-cis-ocropy-deskew -w !{params.workspace_dir} -m ${mets_file} -I ${input_dir} -O ${output_dir} -P level-of-operation page
  """
}

process ocrd_tesserocr_segment_region_4 {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_dir
    val output_dir

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-tesserocr-segment-region -w !{params.workspace_dir} -m ${mets_file} -I ${input_dir} -O ${output_dir} -P padding 5.0 -P find_tables false -P dpi 300
  """
}

process ocrd_segment_repair_5 {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_dir
    val output_dir

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-segment-repair -w !{params.workspace_dir} -m ${mets_file} -I ${input_dir} -O ${output_dir} -P plausibilize true -P plausibilize_merge_min_overlap 0.7
  """
}

process ocrd_cis_ocropy_clip_6 {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_dir
    val output_dir

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-cis-ocropy-clip -w !{params.workspace_dir} -m ${mets_file} -I ${input_dir} -O ${output_dir}
  """
}

process ocrd_cis_ocropy_segment_7 {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_dir
    val output_dir

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-cis-ocropy-segment -w !{params.workspace_dir} -m ${mets_file} -I ${input_dir} -O ${output_dir} -P dpi 300
  """
}

process ocrd_cis_ocropy_dewarp_8 {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_dir
    val output_dir

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-cis-ocropy-dewarp -w !{params.workspace_dir} -m ${mets_file} -I ${input_dir} -O ${output_dir}
  """
}

process ocrd_tesserocr_recognize_9 {
  maxForks 1
  cpus params.cpus
  memory params.ram
  debug true

  input:
    path mets_file
    val input_dir
    val output_dir

  output:
    path mets_file

  script:
  """
  ${params.singularity_wrapper} ocrd-tesserocr-recognize -w !{params.workspace_dir} -m ${mets_file} -I ${input_dir} -O ${output_dir} -P model Fraktur
  """
}

workflow {
  main:
    ocrd_cis_ocropy_binarize_0(params.mets, params.input_file_group, "OCR-D-BINPAGE")
    ocrd_anybaseocr_crop_1(ocrd_cis_ocropy_binarize_0.out, "OCR-D-BINPAGE", "OCR-D-SEG-PAGE-ANYOCR")
    ocrd_cis_ocropy_denoise_2(ocrd_anybaseocr_crop_1.out, "OCR-D-SEG-PAGE-ANYOCR", "OCR-D-DENOISE-OCROPY")
    ocrd_cis_ocropy_deskew_3(ocrd_cis_ocropy_denoise_2.out, "OCR-D-DENOISE-OCROPY", "OCR-D-DESKEW-OCROPY")
    ocrd_tesserocr_segment_region_4(ocrd_cis_ocropy_deskew_3.out, "OCR-D-DESKEW-OCROPY", "OCR-D-SEG-BLOCK-TESSERACT")
    ocrd_segment_repair_5(ocrd_tesserocr_segment_region_4.out, "OCR-D-SEG-BLOCK-TESSERACT", "OCR-D-SEGMENT-REPAIR")
    ocrd_cis_ocropy_clip_6(ocrd_segment_repair_5.out, "OCR-D-SEGMENT-REPAIR", "OCR-D-CLIP")
    ocrd_cis_ocropy_segment_7(ocrd_cis_ocropy_clip_6.out, "OCR-D-CLIP", "OCR-D-SEGMENT-OCROPY")
    ocrd_cis_ocropy_dewarp_8(ocrd_cis_ocropy_segment_7.out, "OCR-D-SEGMENT-OCROPY", "OCR-D-DEWARP")
    ocrd_tesserocr_recognize_9(ocrd_cis_ocropy_dewarp_8.out, "OCR-D-DEWARP", "OCR-D-OCR")
}

