import structlog
import re
from typing import Any, Dict, List
from agents.base import BaseAgent

logger = structlog.get_logger()

class DeveloperAgent(BaseAgent):
    """Developer Agent for writing the application code."""
    
    @property
    def name(self) -> str:
        return "Developer Agent"

    @property
    def system_prompt_file(self) -> str:
        return "developer_agent.txt"

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Runs the Developer agent on requirements and architecture."""
        issue_iid = context['issue_iid']
        title = context.get("issue_title")
        description = context.get("issue_description")
        requirements_path = context.get('requirements_path')
        diagram_paths = context.get('diagram_paths', [])
        
        logger.info("developer_agent_start", issue_iid=issue_iid)
        
        requirements = ""
        if requirements_path:
            requirements = self.gitlab.get_repository_file(requirements_path, context['branch_name'])
            
        diagrams_content = ""
        for path in diagram_paths:
            content = self.gitlab.get_repository_file(path, context['branch_name'])
            diagrams_content += f"\nFile: {path}\n{content}\n"
            
        # TASK 7: FIX AI PROMPT
        system_prompt = f"""
You are a Lead Developer building a NEW application project.

STRICT RULES:
- DO NOT use existing repository structure (agents/, orchestrator/, tools/)
- DO NOT create any system-level folders from this repo
- ONLY create a fresh application for the user's request

Project: {title}
Description: {description}

Generate ONLY:
- backend/ (FastAPI or Flask)
- frontend/ (React or Vue or HTML/JS)
- README.md

Return code using ---FILE_BOUNDARY--- and FILE: path/to/file.py format.
"""
        user_prompt = f"Develop the application for: {title}\n\nRequirements:\n{requirements}\n\nArchitecture:\n{diagrams_content}"
        llm_response = self.llm.call(system_prompt, user_prompt)
        
        files = self._parse_files(llm_response)
        
        return {
            "code_files_content": files
        }

    def _parse_files(self, response: str) -> Dict[str, str]:
        """Parses individual files from the LLM response."""
        files = {}
        # Splitting by ---FILE_BOUNDARY---
        blocks = response.split("---FILE_BOUNDARY---")
        
        for block in blocks:
            block = block.strip()
            if not block:
                continue
                
            # Looking for FILE: [path]
            match = re.search(r"FILE:\s*(.+?)\n(.*)", block, re.DOTALL)
            if match:
                path = match.group(1).strip()
                content = match.group(2).strip()
                files[path] = content
                
        return files
