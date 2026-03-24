import time
import structlog
from concurrent.futures import ThreadPoolExecutor
from typing import Any, Dict, Optional
from orchestrator.state import StateManagerInterface, PipelineState
from tools.gitlab_tools import GitLabTools
from tools.llm_tools import LLMClient
from agents.pm_agent import PMAgent
from agents.architect_agent import ArchitectAgent
from agents.uml_agent import UMLAgent
from agents.developer_agent import DeveloperAgent
from agents.review_agent import ReviewAgent
from agents.test_agent import TestAgent
from agents.security_agent import SecurityAgent
from agents.devops_agent import DevOpsAgent
from config import settings

logger = structlog.get_logger()

class Orchestrator:
    """The central state machine orchestrator for the SDLC agents."""
    
    def __init__(self, gitlab: GitLabTools, llm: LLMClient, state_manager: StateManagerInterface):
        self.gitlab = gitlab
        self.llm = llm
        self.state_manager = state_manager
        
        # Initialize agents
        self.pm_agent = PMAgent(gitlab, llm, state_manager)
        self.architect_agent = ArchitectAgent(gitlab, llm, state_manager)
        self.uml_agent = UMLAgent(gitlab, llm, state_manager)
        self.developer_agent = DeveloperAgent(gitlab, llm, state_manager)
        self.review_agent = ReviewAgent(gitlab, llm, state_manager)
        self.test_agent = TestAgent(gitlab, llm, state_manager)
        self.security_agent = SecurityAgent(gitlab, llm, state_manager)
        self.devops_agent = DevOpsAgent(gitlab, llm, state_manager)

    def ensure_branch(self, branch_name: str, base_branch: str = "main") -> str:
        """Checks if a branch exists, creates it if not, and reuses it if it does."""
        try:
            self.gitlab.project.branches.get(branch_name)
            logger.info("branch_exists_reused", branch=branch_name)
            return branch_name
        except Exception:
            try:
                logger.info("branch_creating", branch=branch_name)
                self.gitlab.project.branches.create({
                    "branch": branch_name,
                    "ref": base_branch
                })
                logger.info("branch_created_successfully", branch=branch_name)
                return branch_name
            except Exception as e:
                # Handle potential race condition if branch was created between get and create
                try:
                    self.gitlab.project.branches.get(branch_name)
                    logger.info("branch_exists_reused", branch=branch_name)
                    return branch_name
                except:
                    logger.error("branch_creation_failed", branch=branch_name, error=str(e))
                    raise e

    def handle_event(self, event_type: str, payload: Dict[str, Any]) -> None:
        """Processes incoming GitLab events and routes to agents."""
        print(f"Orchestrator handling event: {event_type}")
        project_id = payload.get("project_id")
        issue_iid = payload.get("issue_iid")
        
        if not issue_iid:
            print(f"ERROR: issue_iid missing in Orchestrator for {event_type}")
            return

        # TASK 2: FIX CONTEXT (CRITICAL) - Fresh context to prevent data leakage
        self.state_manager.clear(project_id, issue_iid)
        context = {
            "project_id": project_id, 
            "issue_iid": issue_iid,
            "issue_title": payload.get("title", "New Task"),
            "issue_description": payload.get("description", "")
        }
        
        # TASK 3: FIX BRANCH CREATION - One branch per issue, reuse if exists
        branch_name = f"feature/issue-{issue_iid}"
        print(f"USING BRANCH: {branch_name}")
        
        try:
            # Try to get existing branch
            self.gitlab.project.branches.get(branch_name)
            print(f"REUSING EXISTING BRANCH: {branch_name}")
        except:
            # Create if not exists
            print(f"CREATING NEW BRANCH: {branch_name}")
            self.gitlab.create_branch(branch_name)

        context.update({
            "branch_name": branch_name,
            "project": self.gitlab.project
        })
        self.state_manager.update_context(project_id, issue_iid, context)

        try:
            # Only handle issue open events for full automation
            if event_type == "issue":
                print(f"STARTING PIPELINE FOR ISSUE #{issue_iid}")
                
                # PM Agent -> REQUIREMENTS_READY
                self._run_agent(self.pm_agent, context, PipelineState.ISSUE_CREATED, PipelineState.REQUIREMENTS_READY)
                context = self.state_manager.get_context(project_id, issue_iid)
                
                # Architect Agent -> ARCHITECTURE_READY
                self._run_agent(self.architect_agent, context, PipelineState.REQUIREMENTS_READY, PipelineState.ARCHITECTURE_READY)
                context = self.state_manager.get_context(project_id, issue_iid)
                
                # Developer Agent -> CODE_READY
                self._run_agent(self.developer_agent, context, PipelineState.ARCHITECTURE_READY, PipelineState.CODE_READY)
                
                print(f"PIPELINE COMPLETED FOR ISSUE #{issue_iid}")

        except Exception as e:
            print(f"Orchestrator Error: {str(e)}")
            logger.exception("orchestrator_failure", error=str(e))

    def _run_agent(self, agent: Any, context: Dict[str, Any], pre_state: PipelineState, post_state: PipelineState) -> None:
        """Helper to run an agent with state transitions and path protection."""
        project_id = context['project_id']
        issue_iid = context['issue_iid']
        branch_name = context['branch_name']
        
        print(f"RUNNING AGENT: {agent.name}")
        self.state_manager.set_state(project_id, issue_iid, pre_state)
        
        try:
            updated_context = agent.run(context)
            self.state_manager.update_context(project_id, issue_iid, updated_context)
            
            # TASK 5: FORCE PROJECT ISOLATION
            base_path = f"projects/issue-{issue_iid}"

            # 1. Handle PM Requirements
            if "requirements_content" in updated_context:
                file_path = f"{base_path}/docs/requirements.md"
                self.gitlab.upsert_file(branch_name, file_path, updated_context["requirements_content"], f"Add requirements for #{issue_iid}")
                self.state_manager.update_context(project_id, issue_iid, {"requirements_path": file_path})

            # 2. Handle Architect Diagrams
            if "diagrams_content" in updated_context:
                diag_paths = []
                for name, content in updated_context["diagrams_content"].items():
                    file_path = f"{base_path}/docs/diagrams/{name}"
                    self.gitlab.upsert_file(branch_name, file_path, content, f"Add architecture {name}")
                    diag_paths.append(file_path)
                self.state_manager.update_context(project_id, issue_iid, {"diagram_paths": diag_paths})
                self.gitlab.post_issue_comment(issue_iid, f"✅ Generated architecture diagrams in `{base_path}/docs/diagrams/`")

            # 2.5 Handle UML Agent Diagrams
            if "uml_diagrams_content" in updated_context:
                for name, content in updated_context["uml_diagrams_content"].items():
                    file_path = f"{base_path}/docs/{name}"
                    self.gitlab.upsert_file(branch_name, file_path, content, f"Add UML {name}")
                self.gitlab.post_issue_comment(issue_iid, f"✅ Generated UML diagrams in `{base_path}/docs/`")

            # 3. Handle Developer Code
            if "code_files_content" in updated_context:
                for original_path, content in updated_context["code_files_content"].items():
                    # TASK 6: BLOCK WRONG PATHS
                    if any(sys_folder in original_path for sys_folder in ["agents/", "orchestrator/", "tools/", "webhooks/"]):
                        print(f"BLOCKED writing to system folder: {original_path}")
                        continue
                        
                    file_path = f"{base_path}/{original_path}"
                    self.gitlab.upsert_file(branch_name, file_path, content, f"Implement {original_path}")

            self.state_manager.set_state(project_id, issue_iid, post_state)
            print(f"AGENT {agent.name} SUCCESS")

        except Exception as e:
            # TASK 10: ENSURE PIPELINE CONTINUES
            print(f"AGENT {agent.name} FAILED BUT CONTINUING: {str(e)}")
            logger.error("agent_execution_error", agent=agent.name, error=str(e))
