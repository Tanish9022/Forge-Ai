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
        project_id = context['project_id']
        issue_iid = context['issue_iid']
        branch_name = context['branch_name']
        requirements_path = context['requirements_path']
        diagram_paths = context['diagram_paths']
        
        logger.info("developer_agent_start", issue_iid=issue_iid)
        
        requirements = self.gitlab.get_repository_file(requirements_path, branch_name)
        diagrams_content = ""
        for path in diagram_paths:
            content = self.gitlab.get_repository_file(path, branch_name)
            diagrams_content += f"\nFile: {path}\n{content}\n"
            
        user_prompt = f"Requirements:\n{requirements}\n\nArchitecture Diagrams:\n{diagrams_content}"
        system_prompt = self.load_prompt()
        llm_response = self.llm.call(system_prompt, user_prompt)
        
        files = self._parse_files(llm_response)
        
        base_path = f"projects/issue-{issue_iid}"
        actual_files = []
        for original_path, content in files.items():
            file_path = f"{base_path}/{original_path}"
            self.gitlab.commit_file(
                branch=branch_name,
                file_path=file_path,
                content=content,
                commit_message=f"feat: implement {file_path} for issue #{issue_iid}"
            )
            actual_files.append(file_path)
            
        mr_title = f"WIP: AI-SDLC #{issue_iid} - {context.get('issue_title', 'Feature implementation')}"
        mr_description = f"Automated implementation for issue #{issue_iid}.\n\nGenerated files:\n"
        for path in actual_files:
            mr_description += f"- {path}\n"
            
        mr_iid = self.gitlab.open_merge_request(
            source_branch=branch_name,
            title=mr_title,
            description=mr_description
        )
        
        logger.info("developer_agent_complete", mr_iid=mr_iid)
        
        return {
            "mr_iid": mr_iid,
            "generated_files": list(files.keys()),
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
