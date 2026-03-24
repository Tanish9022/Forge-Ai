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
        issue_iid = context['issue_iid']
        branch_name = context['branch_name']
        requirements_path = context.get('requirements_path')
        
        logger.info("architect_agent_start", issue_iid=issue_iid)
        
        requirements_content = ""
        if requirements_path:
            requirements_content = self.gitlab.get_repository_file(requirements_path, branch_name)
        
        # TASK 7: FIX AI PROMPT
        system_prompt = f"""
You are a Solutions Architect designing a NEW application project.

STRICT RULES:
- DO NOT use existing repository structure (agents/, orchestrator/, tools/)
- ONLY design architecture for a fresh application
- Use PlantUML for diagrams

Return individual diagrams wrapped in @startuml and @enduml blocks.
"""
        llm_response = self.llm.call(system_prompt, f"Requirements:\n{requirements_content}")
        
        diagrams = self._parse_diagrams(llm_response)
        
        return {
            "diagrams_content": diagrams
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
