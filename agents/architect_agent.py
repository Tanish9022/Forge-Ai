import structlog
import re
from typing import Any, Dict, List
from agents.base import BaseAgent

logger = structlog.get_logger()

class ArchitectAgent(BaseAgent):
    """System Architect Agent for designing the architecture."""
    
    @property
    def name(self) -> str:
        return "Architect Agent"

    @property
    def system_prompt_file(self) -> str:
        return "architect_agent.txt"

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Runs the Architect agent on a requirements document."""
        project_id = context['project_id']
        issue_iid = context['issue_iid']
        branch_name = context['branch_name']
        requirements_path = context['requirements_path']
        
        logger.info("architect_agent_start", issue_iid=issue_iid)
        
        requirements_content = self.gitlab.get_repository_file(requirements_path, branch_name)
        
        system_prompt = self.load_prompt()
        llm_response = self.llm.call(system_prompt, f"Requirements:\n{requirements_content}")
        
        diagrams = self._parse_diagrams(llm_response)
        
        diagram_paths = []
        for file_name, content in diagrams.items():
            path = f"docs/diagrams/{file_name}"
            self.gitlab.commit_file(
                branch=branch_name,
                file_path=path,
                content=content,
                commit_message=f"docs: design architecture {file_name} for issue #{issue_iid}"
            )
            diagram_paths.append(path)
            
        summary = f"I've generated architecture diagrams for issue #{issue_iid}:\n"
        for path in diagram_paths:
            summary += f"- [{path}](https://gitlab.com/{project_id}/-/blob/{branch_name}/{path})\n"
        
        self.gitlab.post_issue_comment(issue_iid, summary)
        
        logger.info("architect_agent_complete", diagram_count=len(diagram_paths))
        
        return {
            "diagram_paths": diagram_paths
        }

    def _parse_diagrams(self, response: str) -> Dict[str, str]:
        """Parses individual PlantUML diagrams from the LLM response."""
        diagrams = {}
        # Looking for @startuml ... @enduml blocks
        matches = re.findall(r"(@startuml.*?@enduml)", response, re.DOTALL)
        
        # Mapping them based on expected file names
        for match in matches:
            if "use-case" in match.lower() or "actor" in match.lower():
                diagrams["use-case.puml"] = match
            elif "class" in match.lower():
                diagrams["class-diagram.puml"] = match
            elif "sequence" in match.lower():
                diagrams["sequence.puml"] = match
                
        # Fallback names if parsing is ambiguous
        if len(diagrams) < len(matches):
            for i, match in enumerate(matches):
                name = f"diagram_{i}.puml"
                if name not in diagrams.values():
                    diagrams[name] = match
                    
        return diagrams
