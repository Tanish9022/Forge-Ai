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
        issue_iid = context['issue_iid']
        title = context.get("issue_title")
        description = context.get("issue_description")
        
        logger.info("pm_agent_start", issue_iid=issue_iid)
        
        # TASK 7: FIX AI PROMPT
        system_prompt = f"""
You are a Product Manager building a NEW application project.

STRICT RULES:
- DO NOT use existing repository structure (agents/, orchestrator/, tools/)
- ONLY create requirements for a fresh application
- Focus on features, user stories, and acceptance criteria

Project: {title}
Description: {description}
"""
        user_prompt = f"Create a comprehensive requirements document for: {title}\n\nDetails: {description}"
        
        requirements_content = self.llm.call(system_prompt, user_prompt)
        
        return {
            "requirements_content": requirements_content,
            "issue_title": title
        }
