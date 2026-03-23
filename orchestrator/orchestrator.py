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
            logger.warning("missing_issue_iid", event_type=event_type)
            return

        current_state = self.state_manager.get_state(project_id, issue_iid)
        context = self.state_manager.get_context(project_id, issue_iid)
        # Ensure common IDs are in context
        context.update({"project_id": project_id, "issue_iid": issue_iid})
        if mr_iid: context["mr_iid"] = mr_iid
        
        logger.info("orchestrator_event_received", event_type=event_type, state=current_state, issue_iid=issue_iid)

        try:
            if event_type == "issue" and payload.get("action") == "open":
                # Centralize branch creation to prevent duplication from multiple events
                branch_name = f"ai-sdlc/issue-{issue_iid}"
                self.ensure_branch(branch_name)
                
                # Prepare initial context for all agents
                context.update({
                    "project_id": project_id,
                    "issue_iid": issue_iid,
                    "branch_name": branch_name,
                    "project": self.gitlab.project
                })
                
                # PM Agent -> REQUIREMENTS_READY
                logger.info("agent_start", agent="PMAgent", issue_iid=issue_iid)
                self._run_agent(self.pm_agent, context, PipelineState.ISSUE_CREATED, PipelineState.REQUIREMENTS_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                logger.info("agent_end", agent="PMAgent", issue_iid=issue_iid)
                
                # Automatically continue the pipeline
                logger.info("pipeline_automatic_continuation", issue_iid=issue_iid)
                
                # Architect Agent -> ARCHITECTURE_READY
                logger.info("agent_start", agent="ArchitectAgent", issue_iid=issue_iid)
                self._run_agent(self.architect_agent, context, PipelineState.REQUIREMENTS_READY, PipelineState.ARCHITECTURE_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                logger.info("agent_end", agent="ArchitectAgent", issue_iid=issue_iid)
                
                # UML Agent -> UML_READY
                logger.info("agent_start", agent="UMLAgent", issue_iid=issue_iid)
                self._run_agent(self.uml_agent, context, PipelineState.ARCHITECTURE_READY, PipelineState.UML_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                logger.info("agent_end", agent="UMLAgent", issue_iid=issue_iid)
                
                # Developer Agent -> CODE_READY
                logger.info("agent_start", agent="DeveloperAgent", issue_iid=issue_iid)
                self._run_agent(self.developer_agent, context, PipelineState.UML_READY, PipelineState.CODE_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                logger.info("agent_end", agent="DeveloperAgent", issue_iid=issue_iid)
                
                # Review Agent -> REVIEW_APPROVED
                logger.info("agent_start", agent="ReviewAgent", issue_iid=issue_iid)
                self._run_agent(self.review_agent, context, PipelineState.CODE_READY, PipelineState.REVIEW_APPROVED)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                logger.info("agent_end", agent="ReviewAgent", issue_iid=issue_iid)
                
                # Test Agent -> TESTS_READY
                logger.info("agent_start", agent="TestAgent", issue_iid=issue_iid)
                self._run_agent(self.test_agent, context, PipelineState.REVIEW_APPROVED, PipelineState.TESTS_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                logger.info("agent_end", agent="TestAgent", issue_iid=issue_iid)
                
                # Security Agent -> SECURITY_READY
                logger.info("agent_start", agent="SecurityAgent", issue_iid=issue_iid)
                self._run_agent(self.security_agent, context, PipelineState.TESTS_READY, PipelineState.SECURITY_READY)
                context.update(self.state_manager.get_context(project_id, issue_iid))
                logger.info("agent_end", agent="SecurityAgent", issue_iid=issue_iid)
                
                # DevOps Agent -> DONE
                logger.info("agent_start", agent="DevOpsAgent", issue_iid=issue_iid)
                self._run_agent(self.devops_agent, context, PipelineState.SECURITY_READY, PipelineState.DONE)
                logger.info("agent_end", agent="DevOpsAgent", issue_iid=issue_iid)
                
            elif event_type == "push" and "docs/requirements.md" in payload.get("added_files", []) + payload.get("modified_files", []):
                self._run_agent(self.architect_agent, context, PipelineState.REQUIREMENTS_READY, PipelineState.ARCHITECTURE_READY)
                
            elif event_type == "push" and any(f.endswith("architecture.md") for f in payload.get("added_files", []) + payload.get("modified_files", [])):
                self._run_agent(self.uml_agent, context, PipelineState.ARCHITECTURE_READY, PipelineState.UML_READY)
                
            elif event_type == "push" and any(f.endswith(".puml") for f in payload.get("added_files", []) + payload.get("modified_files", [])):
                if current_state == PipelineState.UML_READY:
                    self._run_agent(self.developer_agent, context, PipelineState.UML_READY, PipelineState.CODE_READY)
                    
            elif event_type == "merge_request" and payload.get("action") == "open":
                self._run_agent(self.review_agent, context, PipelineState.CODE_READY, PipelineState.REVIEW_APPROVED)
                
            elif event_type == "note" and "APPROVED" in payload.get("note", "").upper() and payload.get("noteable_type") == "MergeRequest":
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
                self._run_agent(self.devops_agent, context, PipelineState.SECURITY_READY, PipelineState.DONE)
                
        except Exception as e:
            logger.exception("orchestrator_agent_failure", error=str(e), issue_iid=issue_iid)
            self.state_manager.set_state(project_id, issue_iid, PipelineState.HUMAN_INTERVENTION_REQUIRED)
            self.gitlab.post_issue_comment(issue_iid, f"❌ Pipeline failed: {str(e)}. Human intervention required.")

    def _run_agent(self, agent: Any, context: Dict[str, Any], pre_state: PipelineState, post_state: PipelineState) -> None:
        """Helper to run an agent with state transitions and retries."""
        project_id = context['project_id']
        issue_iid = context['issue_iid']
        
        self.state_manager.set_state(project_id, issue_iid, pre_state)
        
        # Retry logic
        max_retries = settings.AGENT_MAX_RETRIES
        for attempt in range(max_retries + 1):
            try:
                updated_context = agent.run(context)
                self.state_manager.update_context(project_id, issue_iid, updated_context)
                self.state_manager.set_state(project_id, issue_iid, post_state)
                return
            except Exception as e:
                if attempt == max_retries:
                    raise e
                logger.warning("agent_retry", agent=agent.name, attempt=attempt + 1, error=str(e))
                time.sleep(2 ** attempt)
