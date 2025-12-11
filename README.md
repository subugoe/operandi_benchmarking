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

# Execution results

## First cycle 
ExecutionResults directory contains the results of the first cycle - with OCR-D processors based on core v2.*

## Second cycle
ExecutionResults2 directory contains the results of the first cycle - with OCR-D processors based on core v2.*

## Summary of results of all cycles

- The `stats` pdf contains summary tables with all results.

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

