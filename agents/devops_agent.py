import time
import structlog
import re
from typing import Any, Dict, List
from agents.base import BaseAgent

logger = structlog.get_logger()

class DevOpsAgent(BaseAgent):
    """DevOps Agent for CI/CD and deployment."""
    
    @property
    def name(self) -> str:
        return "DevOps Agent"

    @property
    def system_prompt_file(self) -> str:
        return "devops_agent.txt"

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Runs the DevOps agent on the project structure."""
        branch_name = context['branch_name']
        mr_iid = context.get('mr_iid')
        
        logger.info("devops_agent_start", branch=branch_name)
        
        # Gathering information about the project
        all_files = self.gitlab.list_repository_files("", branch_name)
        file_list_str = "\n".join(all_files)
        
        user_prompt = f"Existing Files:\n{file_list_str}\n\nProject Structure:\n"
        # We could add more details here if needed
        
        system_prompt = self.load_prompt()
        llm_response = self.llm.call(system_prompt, user_prompt)
        
        files = self._parse_files(llm_response)
        
        for file_path, content in files.items():
            self.gitlab.commit_file(
                branch=branch_name,
                file_path=file_path,
                content=content,
                commit_message=f"chore: generate devops config {file_path}"
            )
            
        # Trigger pipeline
        pipeline_id = self.gitlab.trigger_pipeline(branch_name)
        logger.info("pipeline_triggered", pipeline_id=pipeline_id)
        
        # Poll status
        status = "pending"
        for _ in range(30): # 30 * 10s = 5 minutes
            status = self.gitlab.get_pipeline_status(pipeline_id)
            if status in ["success", "failed", "canceled", "skipped"]:
                break
            time.sleep(10)
            
        if status == "success" and mr_iid:
            mr = self.gitlab.project.mergerequests.get(mr_iid)
            if mr.title.startswith("WIP:"):
                mr.title = mr.title.replace("WIP:", "").strip()
                mr.save()
            self.gitlab.post_mr_comment(mr_iid, "✅ Pipeline passed. Removing WIP status.")
            
        logger.info("devops_agent_complete", final_status=status)
        
        return {
            "pipeline_id": pipeline_id,
            "final_status": status
        }

    def _parse_files(self, response: str) -> Dict[str, str]:
        """Parses individual files from the LLM response."""
        files = {}
        blocks = response.split("---FILE_BOUNDARY---")
        
        for block in blocks:
            block = block.strip()
            if not block:
                continue
                
            match = re.search(r"FILE:\s*(.+?)\n(.*)", block, re.DOTALL)
            if match:
                path = match.group(1).strip()
                content = match.group(2).strip()
                files[path] = content
                
        return files
