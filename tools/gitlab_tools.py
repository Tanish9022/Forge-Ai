import gitlab
import structlog
from typing import Dict, List, Optional
from config import settings

logger = structlog.get_logger()

class GitLabTools:
    """Helper class for interacting with the GitLab API."""
    
    def __init__(self, url: str = settings.GITLAB_URL, token: str = settings.GITLAB_TOKEN, project_id: int = settings.GITLAB_PROJECT_ID):
        # Ensure no trailing slash which can cause 403 redirects
        self.url = url.rstrip('/')
        self.token = token
        self.project_id = project_id
        
        self.gl = gitlab.Gitlab(
            self.url, 
            private_token=self.token,
            timeout=30
        )
        self._project = None

    @property
    def project(self):
        """Lazy-loaded project object."""
        if self._project is None:
            try:
                self._project = self.gl.projects.get(self.project_id)
            except Exception as e:
                logger.error("gitlab_project_access_failed", 
                             url=self.url, 
                             project_id=self.project_id,
                             error_type=type(e).__name__,
                             error=str(e))
                raise
        return self._project

    def get_issue(self, issue_iid: int) -> Dict:
        """Retrieves details for a specific issue."""
        issue = self.project.issues.get(issue_iid)
        return issue.attributes

    def create_branch(self, branch_name: str, ref: str = 'main') -> None:
        """Creates a new branch in GitLab."""
        try:
            print(f"ATTEMPTING TO CREATE BRANCH: {branch_name} from {ref}")
            self.project.branches.create({
                "branch": branch_name,
                "ref": ref
            })
            print("BRANCH CREATED SUCCESSFULLY")
            logger.info("branch_created_successfully", branch=branch_name)
        except Exception as e:
            print("BRANCH CREATION FAILED:", str(e))
            logger.error("branch_creation_failed", branch=branch_name, error=str(e))
            raise e

    def ensure_branch(self, branch_name: str, ref: str = 'main') -> str:
        """Ensures a branch exists by creating it if it doesn't already exist."""
        try:
            self.project.branches.get(branch_name)
            logger.info("branch_exists_reused", branch=branch_name)
            return branch_name
        except Exception:
            try:
                self.project.branches.create({'branch': branch_name, 'ref': ref})
                logger.info("branch_created_successfully", branch=branch_name)
                return branch_name
            except Exception as e:
                # Handle potential race condition
                try:
                    self.project.branches.get(branch_name)
                    logger.info("branch_exists_reused", branch=branch_name)
                    return branch_name
                except:
                    logger.error("branch_creation_failed", branch=branch_name, error=str(e))
                    raise

    def create_file(self, branch: str, file_path: str, content: str, commit_message: str) -> None:
        """Creates a new file in GitLab with logging."""
        try:
            print(f"CREATING FILE: {file_path}")
            print(f"ON BRANCH: {branch}")
            self.project.files.create({
                "file_path": file_path,
                "branch": branch,
                "content": content,
                "commit_message": commit_message
            })
            print("FILE CREATED SUCCESSFULLY")
            logger.info("file_created_successfully", file=file_path, branch=branch)
        except Exception as e:
            print(f"FILE CREATION FAILED: {str(e)}")
            logger.error("file_creation_failed", file=file_path, branch=branch, error=str(e))
            raise e

    def commit_file(self, branch: str, file_path: str, content: str, commit_message: str) -> None:
        """Commits or updates a file."""
        try:
            try:
                self.project.files.get(file_path=file_path, ref=branch)
                action = 'update'
            except:
                action = 'create'
                
            data = {
                'branch': branch,
                'commit_message': commit_message,
                'actions': [{
                    'action': action,
                    'file_path': file_path,
                    'content': content,
                }]
            }
            self.project.commits.create(data)
        except Exception as e:
            logger.error("commit_failed", file=file_path, error=str(e))
            raise

    def open_merge_request(self, source_branch: str, title: str, description: str, target_branch: str = 'main') -> int:
        """Opens a new merge request."""
        mr = self.project.mergerequests.create({
            'source_branch': source_branch,
            'target_branch': target_branch,
            'title': title,
            'description': description
        })
        return mr.iid

    def post_issue_comment(self, issue_iid: int, body: str) -> None:
        """Adds a comment to an issue."""
        issue = self.project.issues.get(issue_iid)
        issue.notes.create({'body': body})

    def post_mr_comment(self, mr_iid: int, body: str) -> None:
        """Adds a comment to a merge request."""
        mr = self.project.mergerequests.get(mr_iid)
        mr.notes.create({'body': body})

    def post_mr_inline_comment(self, mr_iid: int, file_path: str, line: int, body: str) -> None:
        """Adds an inline comment to a merge request."""
        mr = self.project.mergerequests.get(mr_iid)
        diffs = mr.diffs.list()
        if not diffs: return
            
        mr.discussions.create({
            'body': body,
            'position': {
                'base_sha': diffs[0].base_commit_sha,
                'start_sha': diffs[0].start_commit_sha,
                'head_sha': diffs[0].head_commit_sha,
                'new_path': file_path,
                'new_line': line,
                'position_type': 'text'
            }
        })

    def get_mr_diff(self, mr_iid: int) -> str:
        """Retrieves the diff for an MR."""
        mr = self.project.mergerequests.get(mr_iid)
        changes = mr.changes()
        return "".join([f"File: {c['new_path']}\n{c['diff']}\n" for c in changes['changes']])

    def add_mr_label(self, mr_iid: int, label: str) -> None:
        """Adds a label to an MR."""
        mr = self.project.mergerequests.get(mr_iid)
        mr.labels.append(label)
        mr.save()

    def get_repository_file(self, file_path: str, branch: str) -> str:
        """Retrieves file content."""
        f = self.project.files.get(file_path=file_path, ref=branch)
        return f.decode().decode('utf-8')

    def list_repository_files(self, path: str, branch: str) -> List[str]:
        """Lists files in a path. Returns empty list if path not found."""
        try:
            items = self.project.repository_tree(path=path, ref=branch, recursive=True)
            return [item['path'] for item in items if item['type'] == 'blob']
        except Exception as e:
            if '404' in str(e):
                return []
            raise e

    def trigger_pipeline(self, branch: str) -> int:
        """Triggers a pipeline."""
        return self.project.pipelines.create({'ref': branch}).id

    def get_pipeline_status(self, pipeline_id: int) -> str:
        """Gets pipeline status."""
        return self.project.pipelines.get(pipeline_id).status

    def ping(self) -> bool:
        """Verifies GitLab connection with detailed logging on failure."""
        try:
            self.gl.auth()
            logger.info("gitlab_auth_success", url=self.url)
            
            if not self.project_id:
                logger.warning("gitlab_project_id_missing_skipping_project_check")
                return True # Auth worked at least
                
            self.gl.projects.get(self.project_id)
            logger.info("gitlab_project_access_success", project_id=self.project_id)
            return True
        except Exception as e:
            logger.warning("gitlab_ping_failed", 
                           url=self.url, 
                           project_id=self.project_id, 
                           error_type=type(e).__name__,
                           error=str(e)[:200]) # Log first 200 chars of error
            return False
