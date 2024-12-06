# ocrd_benchmarking
Benchmarking data for OCR-D - Operandi

- The MAX file group of the workspaces were used as an entry file group for the workflows
- The used workflows are inside the workspace folders and also available under `Workflows`
- The mets files used to construct the workspace for each VD is inside the VD folder
- The Nextflow reports follow the naming convention of `report_*cpus`
- The Workflow job (slurm job) outputs follow the naming convention of `*cpus_slurm-job-*`
- The `stats` pdf contains summary tables with results. The boxes having an `ERROR` instead of a time duration means that the workflow job of the same workflow over the same workspace was not possible to execute with the current version of `Operandi`/`ocrd_all`. For CPUs more than 8, more RAM is needed for running in parallel, otherwise the jobs trigger out of memory errors. Regardless of the allocated RAM, 32 CPUs always face different kind of run-time errors.

# Used Nextflow workflows in ocrd process format:
## Default workflow
```
ocrd process \
    "cis-ocropy-binarize -I OCR-D-IMG -O OCR-D-BIN" \
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
    "cis-ocropy-binarize -I OCR-D-IMG -O OCR-D-BIN" \
    "anybaseocr-crop -I OCR-D-BIN -O OCR-D-CROP" \
    "skimage-denoise -I OCR-D-CROP -O OCR-D-BIN-DENOISE -P level-of-operation page" \
    "tesserocr-deskew -I OCR-D-BIN-DENOISE -O OCR-D-BIN-DENOISE-DESKEW -P operation_level page" \
    "tesserocr-segment -I OCR-D-BIN-DENOISE-DESKEW -O OCR-D-SEG -P shrink_polygons true" \
    "cis-ocropy-dewarp -I OCR-D-SEG -O OCR-D-SEG-DEWARP" \
    "tesserocr-recognize -I OCR-D-SEG-DEWARP -O OCR-D-OCR -P textequiv_level glyph -P overwrite_segments true -P model GT4HistOCR_50000000.997_191951"
```

## SBB1 workflow
```
ocrd process \
    "cis-ocropy-binarize -I OCR-D-IMG -O OCR-D-BIN" \
    "tesserocr-segment -I OCR-D-BIN -O OCR-D-SEG" \
    "kraken-recognize -I OCR-D-SEG -O OCR-D-OCR -P model typewriter.mlmodel"
```
## SBB2 workflow
```
ocrd process \
    "olena-binarize -I OCR-D-IMG -O OCR-D-BIN" \
    "tesserocr-recognize -I OCR-D-BIN -O OCR-D-OCR" \
    "fileformat-transform -I OCR-D-OCR -O OCR-D-PAGE2ALTO -P from-to page alto"
```
