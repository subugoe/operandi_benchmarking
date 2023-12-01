# ocrd_benchmarking
Benchmarking data for OCR-D - Operandi

- The MAX file group of the workspaces were used as an entry file group for the workflows
- The used workflows are inside the workspace folders
- The mets files used to construct the workspace for each VD is inside the VD folder
- The Nextflow reports follow the naming convention of `report_*cpus`
- The Workflow job (slurm job) outputs follow the naming convention of `*cpus_slurm-job-*`
- The `stats` pdf contains summary tables with results. The boxes having an `X` instead of a time duration means that the workflow job of the same workflow over the same workspace was not possible to execute with the current version of Operandi. For CPUs more than 8, the mets server from `core` is currently problematic. However, we are already working on fixing that. For VD16 and VD17 there was not a reliable way to address page ranges since `page_ids` do not follow a range pattern. Fortunately, the `core` now offers a CLI tool that can split the pages into chunks in a format ready to be passed to the OCR-D processors. Once the version of `ocrd_all` is updated in Operandi - we will be able to present results for VD16 and VD17 with the integrated mets server.  
