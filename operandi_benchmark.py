from dataclasses import dataclass, field
import logging
from os import environ, makedirs
from os.path import isfile, join
from time import sleep
from typing import List
from zipfile import ZipFile
from operandi_client import OperandiClient

OPERANDI_SERVER_ADDR = environ.get("OPERANDI_SERVER_ADDR", "http://localhost:8000")
OPERANDI_USERNAME = environ.get("OPERANDI_USERNAME", "server_operandi")
OPERANDI_PASSWORD = environ.get("OPERANDI_PASSWORD", "server_operandi")
OPERANDI_RESULTS_DIR = environ.get("OPERANDI_RESULTS_DIR", "/home/mm/Desktop/benchmarking_results")
UNSET_VALUE = "Unset"

NF_WORKFLOWS = {
    "default_workflow":"./Workflows/default_workflow.nf",
    "default_workflow_with_MS":"./Workflows/default_workflow_with_MS.nf",
    "odem_workflow":"./Workflows/odem_workflow.nf",
    "odem_workflow_with_MS":"./Workflows/odem_workflow_with_MS.nf",
    "sbb_workflow1_with_MS":"./Workflows/sbb_workflow1_with_MS.nf",
    "sbb_workflow2_with_MS":"./Workflows/sbb_workflow2_with_MS.nf"
}

OCRD_WORKSPACE_ZIPS = {
    "VD16":"./VD16/urn_nbn_de_gbv_3_1-326439.ocrd.zip",
    "VD17":"./VD17/urn_nbn_de_bsz_14-db-id3272770845.ocrd.zip",
    "VD18":"./VD18/PPN1023134829.ocrd.zip",
    "Fraktur":"./FontBased/Fraktur/PPN841193452.ocrd.zip",
    "Antiqua":"./FontBased/Antiqua/PPN63511240X.ocrd.zip"
}

@dataclass()
class WorkflowJobData:
    vd_workspace: str
    nf_workflow_path: str
    workspace_zip_path: str
    input_file_grp: str
    cpus: int
    ram: int
    workflow_id: str = field(default=UNSET_VALUE, init=False)
    workspace_id: str = field(default=UNSET_VALUE,init=False)
    workflow_job_id: str = field(default=UNSET_VALUE,init=False)
    workflow_job_status: str = field(default=UNSET_VALUE,init=False)
    download_path_workspace_zip: str = field(default=UNSET_VALUE,init=False)
    download_path_workflow_job_zip: str = field(default=UNSET_VALUE,init=False)

class OperandiBenchmark:
    def __init__(self, server_address: str, auth_username: str, auth_password: str):
        logging.basicConfig(
            level=logging.INFO,
            format="%(levelname) -7s %(asctime)s %(name) -30s %(funcName) -35s %(lineno) -5d: %(message)s"
        )
        self.logger = logging.getLogger("operandi_benchmark")
        self.logger.setLevel(logging.INFO)
        self.operandi_client = OperandiClient(
            server_address=server_address,
            auth_username=auth_username,
            auth_password=auth_password
        )
        self.workflow_jobs_data = []

    def _verify_existence_files(self, use_workflows: List[str], use_workspaces: List[str], use_file_groups: List[str]):
        missing_files = []
        self.logger.info("Verifying existence of Nextflow workflows...")
        for workflow in use_workflows:
            workflow_path = NF_WORKFLOWS.get(workflow, None)
            if not workflow_path or not isfile(workflow_path):
                missing_files.append(workflow)
        if missing_files:
            raise ValueError(f"There are missing workflow files: {missing_files}")

        self.logger.info("Verifying existence of ocrd zip workspaces...")
        for workspace in use_workspaces:
            workspace_zip_path = OCRD_WORKSPACE_ZIPS.get(workspace, None)
            if not workspace_zip_path or not isfile(workspace_zip_path):
                missing_files.append(workspace)
        if missing_files:
            raise ValueError(f"There are missing ocrd workspace zip files: {missing_files}")

        self.logger.info("Verifying existence of input file group in ocrd workspace zips...")
        for workspace in use_workspaces:
            # existence already verified above
            workspace_zip_path = OCRD_WORKSPACE_ZIPS[workspace]
            zip_file = ZipFile(file=workspace_zip_path, mode="r")
            for file_group in use_file_groups:
                if f"data/{file_group}/" not in zip_file.namelist():
                    missing_files.append(f"{workspace}: {file_group}")
        if missing_files:
            raise ValueError(f"There are missing file groups files: {missing_files}")

    def _print_workflow_jobs_data(self, tidy: bool = True):
        if not tidy:
            for wf_job_data in self.workflow_jobs_data:
                self.logger.info(wf_job_data)
            return
        current_workflow = None
        current_workspace = None
        for wf_job_data in self.workflow_jobs_data:
            if current_workflow != wf_job_data.nf_workflow_path:
                current_workflow = wf_job_data.nf_workflow_path
                self.logger.info(f"Workflow: {current_workflow}")
            if current_workspace != wf_job_data.workspace_zip_path:
                current_workspace = wf_job_data.workspace_zip_path
                self.logger.info(f"Workspace: {current_workspace}")
            self.logger.info(
                f"CPUS[{wf_job_data.cpus:2d}], "
                f"RAM[{wf_job_data.ram}], "
                f"STATUS[{wf_job_data.workflow_job_status}], "
                f"Job_ID[{wf_job_data.workflow_job_id}]"
            )

    def prepare_workflow_jobs_data(
        self,
        use_workflows: List[str],
        use_workspaces: List[str],
        use_file_groups: List[str],
        use_cpus: List[int],
        use_ram: List[int]
    ):
        self._verify_existence_files(use_workflows, use_workspaces, use_file_groups)
        for workflow in use_workflows:
            nf_workflow_path = NF_WORKFLOWS[workflow]
            for vd_workspace in use_workspaces:
                workspace_zip_path = OCRD_WORKSPACE_ZIPS[vd_workspace]
                for file_group in use_file_groups:
                    for cpu_amount in use_cpus:
                        for ram_amount in use_ram:
                            wf_job_data = WorkflowJobData(
                                vd_workspace=vd_workspace,
                                nf_workflow_path=nf_workflow_path,
                                workspace_zip_path=workspace_zip_path,
                                input_file_grp=file_group,
                                cpus=cpu_amount,
                                ram=ram_amount
                            )
                            self.workflow_jobs_data.append(wf_job_data)
                            self.logger.debug(f"Created workflow job data: {wf_job_data}")

    def _run_workflow_job(self, wf_job_data: WorkflowJobData) -> WorkflowJobData:
        workflow_id = self.operandi_client.post_workflow(wf_job_data.nf_workflow_path)
        workspace_id = self.operandi_client.post_workspace_zip(wf_job_data.workspace_zip_path)
        workflow_job_id = self.operandi_client.post_workflow_job(
            workflow_id=workflow_id,
            workspace_id=workspace_id,
            input_file_grp=wf_job_data.input_file_grp,
            mets_base="mets.xml",
            cpus=wf_job_data.cpus,
            ram=wf_job_data.ram
        )
        wf_job_data.workflow_id = workflow_id
        wf_job_data.workspace_id = workspace_id
        wf_job_data.workflow_job_id = workflow_job_id
        wf_job_data.workflow_job_status = "QUEUED"
        return wf_job_data

    def run_workflow_jobs(self) -> None:
        self.logger.info("Starting to run all workflow jobs")
        for wf_job_data in self.workflow_jobs_data:
            self._run_workflow_job(wf_job_data)

    def _update_workflow_job_status(self, wf_job_data: WorkflowJobData) -> str:
        workflow_job_status = self.operandi_client.get_workflow_job_state(
            workflow_id=wf_job_data.workflow_id,
            job_id=wf_job_data.workflow_job_id
        )
        wf_job_data.workflow_job_status = workflow_job_status
        return workflow_job_status

    def _update_workflow_job_statuses(self) -> bool:
        update_occurred = False
        for wf_job_data in self.workflow_jobs_data:
            sleep(1)
            if wf_job_data.workflow_job_status != "SUCCESS" and wf_job_data.workflow_job_status != "FAILED":
                self._update_workflow_job_status(wf_job_data)
                update_occurred = True
        return update_occurred

    def poll_till_jobs_end(self, wait_between=90):
        update_occurred = True
        while update_occurred:
            update_occurred = self._update_workflow_job_statuses()
            self._print_workflow_jobs_data()
            sleep(wait_between)
            self.logger.info(f"Next update will happen after {wait_between} seconds.")

    def _download_results_workspace(self, wf_job_data: WorkflowJobData) -> str:
        download_dir = join(OPERANDI_RESULTS_DIR, wf_job_data.vd_workspace)
        makedirs(name=download_dir, mode = 0o777, exist_ok = True)
        workspace_zip_path = self.operandi_client.download_workspace(
            workspace_id=wf_job_data.workspace_id,
            download_dir=download_dir,
            zip_name=f"ws_{wf_job_data.cpus}_{wf_job_data.ram}_{wf_job_data.workflow_job_id}"
        )
        wf_job_data.download_path_workspace_zip = workspace_zip_path
        return workspace_zip_path

    def _download_results_workflow_job(self, wf_job_data: WorkflowJobData) -> str:
        download_dir = join(OPERANDI_RESULTS_DIR, wf_job_data.vd_workspace)
        makedirs(name=download_dir, mode = 0o777, exist_ok = True)
        wf_job_zip_path = self.operandi_client.download_workflow_job(
            workflow_id=wf_job_data.workflow_id,
            job_id=wf_job_data.workflow_job_id,
            download_dir=download_dir,
            zip_name=f"wf_{wf_job_data.cpus}_{wf_job_data.ram}_{wf_job_data.workflow_job_id}"
        )
        wf_job_data.download_path_workflow_job_zip = wf_job_zip_path
        return wf_job_zip_path

    def download_all_results(self):
        self.logger.info("Downloading all results")
        for wf_job_data in self.workflow_jobs_data:
            sleep(1)
            self._download_results_workspace(wf_job_data)
            sleep(1)
            self._download_results_workflow_job(wf_job_data)
            sleep(1)

def main():
    operandi_benchmarking = OperandiBenchmark(OPERANDI_SERVER_ADDR, OPERANDI_USERNAME, OPERANDI_PASSWORD)
    operandi_benchmarking.prepare_workflow_jobs_data(
        use_workflows=[
            "default_workflow"
        ],
        use_workspaces=[
            "VD16",
            "VD17",
            "VD18"
        ],
        use_file_groups=[
            "MAX"
        ],
        use_cpus=[1, 2, 4, 8],
        use_ram=[32]
    )
    operandi_benchmarking.run_workflow_jobs()
    operandi_benchmarking.poll_till_jobs_end()
    # operandi_benchmarking.download_all_results()

if __name__ == '__main__':
    main()
