# ocrd_benchmarking
Benchmarking data for OCR-D - Operandi

# Preparation of the input data
- The mets files used to construct the workspace for each VD are inside their respective VD folder under `Workspaces`. Inside each workspace there is a ready to use script `build_workspace_zip.sh` which builds the workspace based on the mets file of the specific workspace. A `OCR-D core` is a prerequisite to run the script. 
- The used workflows are inside the workspace folders and also available under `Workflows`. Each workflow is also provided in a code block at the end of this file.
- The `MAX` file group of the workspaces were used as an entry file group for the workflows.
- The usual allocation of resources is 8GB of RAM per 1 CPU core. For CPUs more than 8, more RAM is needed for running in parallel, otherwise the jobs trigger out of memory errors.

# What output data is produced
- The Nextflow reports follow the naming convention of `report_*cpus`
- The Nextflow traces follow the naming convention of `trace_*cpus`
- The Workflow job (slurm job) outputs follow the naming convention of `*cpus_slurm-job-*`
- Many other irrelevant for the benchmarking logs which are excluded from this repository

# Execution results

## First cycle 
ExecutionResults directory contains the results of the first cycle - with OCR-D processors based on core v2.*

The main objective of the first cycle was to find out how the processors scale based on different amount of provided RAM and CPU resources.

## Second cycle
ExecutionResults2 directory contains the results of the first cycle - with OCR-D processors based on core v3.*

The main objective of the second cycle was to verify if core v3.* is improving the overall speed of the used OCR-D processors. Only a single VD18 workspace was used since that is enough to show some relevant comparison. Moreover, the workflows were tested only with 2, 4, and 8 cpus.

`Warning`: The results for the `default_workflow` and `default_workflow_with_MS` are missing since the model used in the first cycle of these workflows was no longer functional as of v3.* of OCR-D core. The slurm job output logs were still provided as a reference. If another model was used, the results of the workflows would not have been comparable to the first cycle results.

# Summary of results of all execution cycles
- The `stats` pdf contains summary tables with all results from both cycles.

`Important note`: Keep in mind that the workflows of the first cycle were executed on the SCC HPC and the workflows of the second cycle were executed on the NHR HPC. Although the provided amount of 
CPUs and RAM is comparable, the processors themselfs are not.  

# Used Nextflow workflows in ocrd process format:
## Default workflow
```
ocrd process \
    "cis-ocropy-binarize -I MAX -O OCR-D-BIN" \
    "anybaseocr-crop -I OCR-D-BIN -O OCR-D-CROP" \
    "skimage-binarize -I OCR-D-CROP -O OCR-D-BIN2 -P method li" \
    "skimage-denoise -I OCR-D-BIN2 -O OCR-D-BIN-DENOISE -P level-of-operation page" \
    "tesserocr-deskew -I OCR-D-BIN-DENOISE -O OCR-D-BIN-DENOISE-DESKEW -P operation_level page" \
    "cis-ocropy-segment -I OCR-D-BIN-DENOISE-DESKEW -O OCR-D-SEG -P level-of-operation page" \
    "cis-ocropy-dewarp -I OCR-D-SEG -O OCR-D-SEG-LINE-RESEG-DEWARP" \
    "calamari-recognize -I OCR-D-SEG-LINE-RESEG-DEWARP -O OCR-D-OCR -P checkpoint_dir qurator-gt4histocr-1.0"
```

## Odem workflow
```
ocrd process \
    "cis-ocropy-binarize -I MAX -O OCR-D-BIN" \
    "anybaseocr-crop -I OCR-D-BIN -O OCR-D-CROP" \
    "skimage-denoise -I OCR-D-CROP -O OCR-D-BIN-DENOISE -P level-of-operation page" \
    "tesserocr-deskew -I OCR-D-BIN-DENOISE -O OCR-D-BIN-DENOISE-DESKEW -P operation_level page" \
    "tesserocr-segment -I OCR-D-BIN-DENOISE-DESKEW -O OCR-D-SEG -P shrink_polygons true" \
    "cis-ocropy-dewarp -I OCR-D-SEG -O OCR-D-SEG-DEWARP" \
    "tesserocr-recognize -I OCR-D-SEG-DEWARP -O OCR-D-OCR -P textequiv_level glyph -P overwrite_segments true -P model GT4HistOCR_50000000.997_191951"
```

Workflows from Staatsbibliothek zu Berlin

## SBB workflow
```
ocrd process \
    "tesserocr-recognize -I MAX -O OCR-D-OCR"
```

## SBB2 workflow
```
ocrd process \
    "olena-binarize -I MAX -O OCR-D-BIN" \
    "tesserocr-recognize -I OCR-D-BIN -O OCR-D-OCR" \
    "fileformat-transform -I OCR-D-OCR -O OCR-D-PAGE2ALTO -P from-to page alto"
```

## SBB3 workflow
```
ocrd process \
    "cis-ocropy-binarize -I MAX -O OCR-D-BIN" \
    "tesserocr-segment -I OCR-D-BIN -O OCR-D-SEG" \
    "kraken-recognize -I OCR-D-SEG -O OCR-D-OCR -P model typewriter.mlmodel"
```

