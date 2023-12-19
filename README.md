# ocrd_benchmarking
Benchmarking data for OCR-D - Operandi

- The MAX file group of the workspaces were used as an entry file group for the workflows
- The used workflows are inside the workspace folders and also available under `Workflows`
- The mets files used to construct the workspace for each VD is inside the VD folder
- The Nextflow reports follow the naming convention of `report_*cpus`
- The Workflow job (slurm job) outputs follow the naming convention of `*cpus_slurm-job-*`
- The `stats` pdf contains summary tables with results. The boxes having an `ERROR` instead of a time duration means that the workflow job of the same workflow over the same workspace was not possible to execute with the current version of `Operandi`/`ocrd_all`. For CPUs more than 8, more RAM is needed for running in parallel, otherwise the jobs trigger out of memory errors. Regardless of the allocated RAM, 32 CPUs always face different kind of run-time errors.
