import json
import structlog
from typing import Any, Dict
from agents.base import BaseAgent

logger = structlog.get_logger()

class ReviewAgent(BaseAgent):
    """Architecture Review Agent for code quality and compliance."""
    
    @property
    def name(self) -> str:
        return "Review Agent"

    @property
    def system_prompt_file(self) -> str:
        return "review_agent.txt"

    async def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Runs the Review agent on a Merge Request diff."""
        mr_iid = context['mr_iid']
        
        logger.info("review_agent_start", mr_iid=mr_iid)
        
        diff = self.gitlab.get_mr_diff(mr_iid)
        
        user_prompt = f"Merge Request Diff:\n{diff}"
        system_prompt = self.load_prompt()
        llm_response = self.llm.call(system_prompt, user_prompt)
        
        review_data = self._parse_json_response(llm_response)
        
        verdict = review_data.get('verdict', 'CHANGES_REQUESTED')
        issues = review_data.get('issues', [])
        
        for issue in issues:
            self.gitlab.post_mr_inline_comment(
                mr_iid=mr_iid,
                file_path=issue['file'],
                line=issue['line'],
                body=f"[{issue['severity']}] {issue['comment']}"
            )
            
        summary = f"Review complete. Verdict: **{verdict}**.\nFound {len(issues)} issues."
        self.gitlab.post_mr_comment(mr_iid, summary)
        
        logger.info("review_agent_complete", verdict=verdict, issue_count=len(issues))
        
        return {
            "review_verdict": verdict,
            "review_issues": issues
        }

    def _parse_json_response(self, response: str) -> Dict[str, Any]:
        """Parses the JSON block from the LLM response."""
        try:
            # Finding the JSON block between curly braces
            start = response.find('{')
            end = response.rfind('}') + 1
            if start != -1 and end != 0:
                return json.loads(response[start:end])
        except Exception as e:
            logger.error("review_agent_parse_error", error=str(e), response=response)
            
        return {"verdict": "CHANGES_REQUESTED", "issues": [{"file": "unknown", "line": 1, "severity": "HIGH", "comment": "Failed to parse review response"}]}
