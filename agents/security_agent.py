import json
import structlog
from typing import Any, Dict
from agents.base import BaseAgent

logger = structlog.get_logger()

class SecurityAgent(BaseAgent):
    """Security Agent for scanning source code."""
    
    @property
    def name(self) -> str:
        return "Security Agent"

    @property
    def system_prompt_file(self) -> str:
        return "security_agent.txt"

    async def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Runs the Security agent on source code."""
        branch_name = context['branch_name']
        mr_iid = context.get('mr_iid')
        
        logger.info("security_agent_start", branch=branch_name)
        
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
        
        security_data = self._parse_json_response(llm_response)
        
        severity = security_data.get('severity', 'LOW')
        
        # Commit the security report
        self.gitlab.commit_file(
            branch=branch_name,
            file_path="security-report.json",
            content=json.dumps(security_data, indent=2),
            commit_message="security: add security report"
        )
        
        if mr_iid:
            if severity == "HIGH":
                self.gitlab.add_mr_label(mr_iid, "security::blocked")
                self.gitlab.post_mr_comment(mr_iid, "🚨 **HIGH SEVERITY SECURITY ISSUES FOUND**. Blocking MR until resolved.")
            else:
                self.gitlab.post_mr_comment(mr_iid, f"Security scan complete. Overall severity: {severity}.")
                
        logger.info("security_agent_complete", severity=severity)
        
        return {
            "security_verdict": severity,
            "security_report_path": "security-report.json"
        }

    def _parse_json_response(self, response: str) -> Dict[str, Any]:
        """Parses the JSON block from the LLM response."""
        try:
            start = response.find('{')
            end = response.rfind('}') + 1
            if start != -1 and end != 0:
                return json.loads(response[start:end])
        except Exception as e:
            logger.error("security_agent_parse_error", error=str(e), response=response)
            
        return {"severity": "LOW", "findings": []}
