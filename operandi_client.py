import logging
from os import environ
from os.path import join
from requests import get, post
from requests.auth import HTTPBasicAuth

class OperandiClient:
    def __init__(
        self,
        server_address: str = environ.get("OPERANDI_SERVER_ADDR", None),
        auth_username: str = environ.get("OPERANDI_USERNAME", None),
        auth_password: str = environ.get("OPERANDI_PASSWORD", None)
    ):
        assert server_address, "Operandi server address not set, set OPERANDI_SERVER_ADDR env"
        assert auth_username, "Operandi username not set, set OPERANDI_USERNAME env"
        assert auth_password, "Operandi password not set, set OPERANDI_PASSWORD env"
        self.server_address = server_address
        self.auth = HTTPBasicAuth(auth_username, auth_password)
        self.logger = logging.getLogger("operandi_client")
        self.logger.setLevel(logging.INFO)

    def receive_file(self, response, download_path):
        with open(download_path, 'wb') as filePtr:
            for chunk in response.iter_content(chunk_size=1024):
                if chunk:
                    filePtr.write(chunk)

    def post_workspace_zip(self, ocrd_zip_path: str) -> str:
        self.logger.info(f"Posting workspace ocrd zip: {ocrd_zip_path}")
        response = post(
            url=f"{self.server_address}/workspace",
            files={"workspace": open(f"{ocrd_zip_path}", "rb")},
            auth=self.auth
        )
        self.logger.debug(response.json())
        workspace_id = response.json().get("resource_id", None)
        if not workspace_id:
            raise ValueError(f"Failed to parse workspace id from response")
        self.logger.info(f"Response workspace id: {workspace_id}")
        return workspace_id

    def post_workflow(self, nf_script_path: str) -> str:
        self.logger.info(f"Posting nextflow script file: {nf_script_path}")
        response = post(
            url=f"{self.server_address}/workflow",
            files={"nextflow_script": open(f"{nf_script_path}", "rb")},
            auth=self.auth
        )
        self.logger.debug(response.json())
        workflow_id = response.json().get("resource_id", None)
        if not workflow_id:
            raise ValueError(f"Failed to parse workflow id from response")
        self.logger.info(f"Response workflow id: {workflow_id}")
        return workflow_id

    def post_workflow_job(
            self,
            workflow_id: str,
            workspace_id: str,
            input_file_grp: str = "DEFAULT",
            mets_base: str = "mets.xml",
            cpus: int = 8,
            ram: int = 32
    ) -> str:
        self.logger.info(f"Posting workflow job with workflow id: {workflow_id} on workspace id: {workspace_id}")
        request_json = {
            "workflow_id": workflow_id,
            "workflow_args": {
                "workspace_id": workspace_id,
                "input_file_grp": input_file_grp,
                "mets_name": mets_base
            },
            "sbatch_args": {
                "cpus": cpus,
                "ram": ram
            }
        }
        self.logger.debug(request_json)
        response = post(
            url=f"{self.server_address}/workflow/{workflow_id}",
            json=request_json,
            auth=self.auth
        )
        self.logger.debug(response.json())
        workflow_job_id = response.json().get("resource_id", None)
        if not workflow_job_id:
            raise ValueError(f"Failed to parse workflow job id from response")
        self.logger.info(f"Response workflow job id: {workflow_job_id}")
        return workflow_job_id

    def get_workflow_job_state(self, workflow_id: str, job_id: str) -> str:
        self.logger.info(f"Checking state of workflow job id: {job_id}")
        response = get(
            url=f"{self.server_address}/workflow/{workflow_id}/{job_id}",
            auth=self.auth
        )
        self.logger.debug(response.json())
        workflow_job_status = response.json().get("job_state", None)
        if not workflow_job_status:
            raise ValueError(f"Failed to parse workflow job state from response")
        return workflow_job_status

    def download_workspace(self, workspace_id: str, download_dir: str, zip_name: str) -> str:
        self.logger.info(f"Getting workspace zip of: {workspace_id}")
        download_path = join(download_dir, f"{zip_name}.ocrd.zip")
        response = get(
            url=f"{self.server_address}/workspace/{workspace_id}",
            headers={"accept": "application/vnd.ocrd+zip"},
            auth=self.auth
        )
        self.receive_file(response=response, download_path=download_path)
        self.logger.info(f"Downloaded workspace ocrd zip to: {download_path}")
        return download_path

    def download_workflow_job(self, workflow_id: str, job_id: str, download_dir: str, zip_name: str) -> str:
        self.logger.info(f"Getting workflow job zip of: {job_id}")
        download_path = join(download_dir, f"{zip_name}.zip")
        response = get(
            url=f"{self.server_address}/workflow/{workflow_id}/{job_id}",
            headers={'accept': 'application/vnd.zip'},
            auth=self.auth
        )
        self.receive_file(response=response, download_path=download_path)
        self.logger.info(f"Downloaded workflow job zip to: {download_path}")
        return download_path
