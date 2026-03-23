import structlog
import re
from typing import Any, Dict, List
from agents.base import BaseAgent

logger = structlog.get_logger()

class TestAgent(BaseAgent):
    """Test Engineer Agent for generating tests and CI config."""
    
    @property
    def name(self) -> str:
        return "Test Agent"

    @property
    def system_prompt_file(self) -> str:
        return "test_agent.txt"

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Runs the Test agent on source files."""
        branch_name = context['branch_name']
        mr_iid = context.get('mr_iid')
        
        logger.info("test_agent_start", branch=branch_name)
        
        # Get source files (everything except docs/ and tests/)
        all_files = self.gitlab.list_repository_files("", branch_name)
        source_files = [f for f in all_files if not f.startswith("docs/") and not f.startswith("tests/")]
        
        sources_content = ""
        for path in source_files:
            content = self.gitlab.get_repository_file(path, branch_name)
            sources_content += f"\nFile: {path}\n{content}\n"
            
        user_prompt = f"Source Code:\n{sources_content}"
        system_prompt = self.load_prompt()
        llm_response = self.llm.call(system_prompt, user_prompt)
        
        files = self._parse_files(llm_response)
        
        for file_path, content in files.items():
            self.gitlab.commit_file(
                branch=branch_name,
                file_path=file_path,
                content=content,
                commit_message=f"test: generate tests for {file_path}"
            )
            
        if mr_iid:
            summary = "I've generated unit and integration tests, and updated `.gitlab-ci.yml`."
            self.gitlab.post_mr_comment(mr_iid, summary)
            
        logger.info("test_agent_complete", test_count=len(files))
        
        return {
            "test_paths": list(files.keys())
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
