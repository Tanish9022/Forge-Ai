import structlog
from typing import Any, Dict
from agents.base import BaseAgent

logger = structlog.get_logger()

class PMAgent(BaseAgent):
    """Product Manager Agent for requirements gathering."""
    
    @property
    def name(self) -> str:
        return "Product Manager Agent"

    @property
    def system_prompt_file(self) -> str:
        return "pm_agent.txt"

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Runs the PM agent on a GitLab issue."""
        project_id = context['project_id']
        issue_iid = context['issue_iid']
        
        logger.info("pm_agent_start", issue_iid=issue_iid)
        
        issue_data = self.gitlab.get_issue(issue_iid)
        title = issue_data['title']
        description = issue_data['description']
        
        user_prompt = f"Title: {title}\nDescription: {description}"
        system_prompt = self.load_prompt()
        
        requirements_content = self.llm.call(system_prompt, user_prompt)
        
        branch_name = f"ai-sdlc/issue-{issue_iid}"
        self.gitlab.ensure_branch(branch_name)
        
        requirements_path = "docs/requirements.md"
        self.gitlab.commit_file(
            branch=branch_name,
            file_path=requirements_path,
            content=requirements_content,
            commit_message=f"docs: define requirements for issue #{issue_iid}"
        )
        
        summary = f"I've analyzed issue #{issue_iid} and generated requirements in docs/requirements.md on branch `{branch_name}`."
        self.gitlab.post_issue_comment(issue_iid, summary)
        
        logger.info("pm_agent_complete", requirements_path=requirements_path)
        
        return {
            "requirements_path": requirements_path,
            "branch_name": branch_name,
            "issue_title": title
        }
