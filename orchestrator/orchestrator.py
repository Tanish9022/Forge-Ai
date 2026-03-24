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
        mr_iid = payload.get("mr_iid")
        
        # If we don't have an issue_iid yet (e.g. push event), try to find it from branch or context
        if not issue_iid:
            if "branch" in payload:
                # Expecting branch: ai-sdlc/issue-123
                if payload["branch"].startswith("ai-sdlc/issue-"):
                    issue_iid = int(payload["branch"].split("-")[-1])
            elif mr_iid:
                # We should have the issue_iid in the context of this MR
                pass
                
        if not issue_iid:
            print(f"ERROR: issue_iid missing in Orchestrator for {event_type}")
            logger.warning("missing_issue_iid", event_type=event_type)
            return

        current_state = self.state_manager.get_state(project_id, issue_iid)
        context = self.state_manager.get_context(project_id, issue_iid)
        # Ensure common IDs are in context
        context.update({"project_id": project_id, "issue_iid": issue_iid})
        if mr_iid: context["mr_iid"] = mr_iid
        
        print(f"Current State: {current_state}, Issue IID: {issue_iid}")
        logger.info("orchestrator_event_received", event_type=event_type, state=current_state, issue_iid=issue_iid)

        try:
            if event_type == "issue":
                print("ISSUE EVENT DETECTED")
                action = payload.get("action")
                
                if action == "open":
                    print("Processing new issue open event")
                    branch_name = f"feature/issue-{issue_iid}"
                    
                    print("CREATING BRANCH:", branch_name)
                    try:
                        self.gitlab.create_branch(branch_name)
                    except Exception as e:
                        print("BRANCH CREATION FAILED:", str(e))
                        # If branch exists, we can continue, but log it
                        if "already exists" not in str(e).lower():
                            raise e
                    
                    # Prepare initial context for all agents
                    context.update({
                        "project_id": project_id,
                        "issue_iid": issue_iid,
                        "branch_name": branch_name,
                        "project": self.gitlab.project
                    })
                    
                    # PM Agent -> REQUIREMENTS_READY
                    self._run_agent(self.pm_agent, context, PipelineState.ISSUE_CREATED, PipelineState.REQUIREMENTS_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                
                # Automatically continue the pipeline
                print("Pipeline continuing automatically...")
                
                # Architect Agent -> ARCHITECTURE_READY
                self._run_agent(self.architect_agent, context, PipelineState.REQUIREMENTS_READY, PipelineState.ARCHITECTURE_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                
                # UML Agent -> UML_READY
                self._run_agent(self.uml_agent, context, PipelineState.ARCHITECTURE_READY, PipelineState.UML_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                
                # Developer Agent -> CODE_READY
                self._run_agent(self.developer_agent, context, PipelineState.UML_READY, PipelineState.CODE_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                
                # Review Agent -> REVIEW_APPROVED
                self._run_agent(self.review_agent, context, PipelineState.CODE_READY, PipelineState.REVIEW_APPROVED)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                
                # Test Agent -> TESTS_READY
                self._run_agent(self.test_agent, context, PipelineState.REVIEW_APPROVED, PipelineState.TESTS_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                
                # Security Agent -> SECURITY_READY
                self._run_agent(self.security_agent, context, PipelineState.TESTS_READY, PipelineState.SECURITY_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                
                # DevOps Agent -> DONE
                self._run_agent(self.devops_agent, context, PipelineState.SECURITY_READY, PipelineState.DONE)
                
            elif event_type == "push" and "docs/requirements.md" in payload.get("added_files", []) + payload.get("modified_files", []):
                print("Processing requirements update")
                self._run_agent(self.architect_agent, context, PipelineState.REQUIREMENTS_READY, PipelineState.ARCHITECTURE_READY)
                
            elif event_type == "push" and any(f.endswith("architecture.md") for f in payload.get("added_files", []) + payload.get("modified_files", [])):
                print("Processing architecture update")
                self._run_agent(self.uml_agent, context, PipelineState.ARCHITECTURE_READY, PipelineState.UML_READY)
                
            elif event_type == "push" and any(f.endswith(".puml") for f in payload.get("added_files", []) + payload.get("modified_files", [])):
                print("Processing UML update")
                if current_state == PipelineState.UML_READY:
                    self._run_agent(self.developer_agent, context, PipelineState.UML_READY, PipelineState.CODE_READY)
                    
            elif event_type == "merge_request" and payload.get("action") == "open":
                print("Processing MR open")
                self._run_agent(self.review_agent, context, PipelineState.CODE_READY, PipelineState.REVIEW_APPROVED)
                
            elif event_type == "note" and "APPROVED" in payload.get("note", "").upper() and payload.get("noteable_type") == "MergeRequest":
                print("Processing approval note")
                self.state_manager.set_state(project_id, issue_iid, PipelineState.REVIEW_APPROVED)
                
                # Parallel execution using ThreadPoolExecutor
                with ThreadPoolExecutor(max_workers=2) as executor:
                    futures = [
                        executor.submit(self.test_agent.run, context),
                        executor.submit(self.security_agent.run, context)
                    ]
                    for future in futures:
                        try:
                            res = future.result()
                            context.update(res)
                        except Exception as e:
                            raise e
                
                self.state_manager.update_context(project_id, issue_iid, context)
                self.state_manager.set_state(project_id, issue_iid, PipelineState.SECURITY_READY)
                
            elif event_type == "push" and "security-report.json" in payload.get("added_files", []):
                print("Processing security report")
                self._run_agent(self.devops_agent, context, PipelineState.SECURITY_READY, PipelineState.DONE)
                
        except Exception as e:
            print(f"Orchestrator Error: {str(e)}")
            logger.exception("orchestrator_agent_failure", error=str(e), issue_iid=issue_iid)
            self.state_manager.set_state(project_id, issue_iid, PipelineState.HUMAN_INTERVENTION_REQUIRED)
            self.gitlab.post_issue_comment(issue_iid, f"❌ Pipeline failed: {str(e)}. Human intervention required.")

    def _run_agent(self, agent: Any, context: Dict[str, Any], pre_state: PipelineState, post_state: PipelineState) -> None:
        """Helper to run an agent with state transitions and retries."""
        project_id = context['project_id']
        issue_iid = context['issue_iid']
        
        print(f"Running agent: {agent.name}")
        logger.info("agent_start", agent=agent.name, issue_iid=issue_iid)
        
        self.state_manager.set_state(project_id, issue_iid, pre_state)
        
        # Retry logic
        max_retries = settings.AGENT_MAX_RETRIES
        for attempt in range(max_retries + 1):
            try:
                updated_context = agent.run(context)
                print("AGENT OUTPUT:", updated_context)
                self.state_manager.update_context(project_id, issue_iid, updated_context)
                
                # Centralized file creation logic based on agent output
                branch_name = updated_context.get("branch_name") or context.get("branch_name")
                
                if branch_name:
                    # Verify branch exists
                    try:
                        self.gitlab.project.branches.get(branch_name)
                    except:
                        print(f"Branch {branch_name} not found, creating it.")
                        self.gitlab.create_branch(branch_name)

                    # 1. PMAgent -> docs/requirements.md
                    if "requirements_content" in updated_context:
                        file_path = "docs/requirements.md"
                        try:
                            self.gitlab.create_file(
                                branch=branch_name,
                                file_path=file_path,
                                content=updated_context["requirements_content"],
                                commit_message=f"Add requirements for issue #{issue_iid}"
                            )
                        except Exception as e:
                            if "already exists" in str(e).lower():
                                self.gitlab.commit_file(branch_name, file_path, updated_context["requirements_content"], f"Update requirements for issue #{issue_iid}")
                            else:
                                print("FILE CREATION FAILED:", str(e))

                    # 2. ArchitectAgent -> docs/diagrams/
                    if "diagrams_content" in updated_context:
                        for file_name, content in updated_context["diagrams_content"].items():
                            file_path = f"docs/diagrams/{file_name}"
                            try:
                                self.gitlab.create_file(
                                    branch=branch_name,
                                    file_path=file_path,
                                    content=content,
                                    commit_message=f"Add architecture diagram {file_name}"
                                )
                            except Exception as e:
                                if "already exists" in str(e).lower():
                                    self.gitlab.commit_file(branch_name, file_path, content, f"Update diagram {file_name}")
                                else:
                                    print("FILE CREATION FAILED:", str(e))

                    # 3. UMLAgent -> docs/
                    if "uml_diagrams_content" in updated_context:
                        for file_name, content in updated_context["uml_diagrams_content"].items():
                            file_path = f"docs/{file_name}"
                            try:
                                self.gitlab.create_file(
                                    branch=branch_name,
                                    file_path=file_path,
                                    content=content,
                                    commit_message=f"Add UML diagram {file_name}"
                                )
                            except Exception as e:
                                if "already exists" in str(e).lower():
                                    self.gitlab.commit_file(branch_name, file_path, content, f"Update UML diagram {file_name}")
                                else:
                                    print("FILE CREATION FAILED:", str(e))

                    # 4. DeveloperAgent -> src/
                    if "code_files_content" in updated_context:
                        for file_path, content in updated_context["code_files_content"].items():
                            try:
                                self.gitlab.create_file(
                                    branch=branch_name,
                                    file_path=file_path,
                                    content=content,
                                    commit_message=f"Implement {file_path}"
                                )
                            except Exception as e:
                                if "already exists" in str(e).lower():
                                    self.gitlab.commit_file(branch_name, file_path, content, f"Update {file_path}")
                                else:
                                    print("FILE CREATION FAILED:", str(e))

                self.state_manager.set_state(project_id, issue_iid, post_state)
                print(f"Agent {agent.name} completed successfully")
                logger.info("agent_end", agent=agent.name, issue_iid=issue_iid)
                return
            except Exception as e:
                if attempt == max_retries:
                    print(f"Agent {agent.name} failed after {max_retries} retries")
                    raise e
                print(f"Agent {agent.name} retry {attempt + 1}/{max_retries} due to: {str(e)}")
                logger.warning("agent_retry", agent=agent.name, attempt=attempt + 1, error=str(e))
                time.sleep(2 ** attempt)
