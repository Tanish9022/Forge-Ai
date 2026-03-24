import structlog
import re
from typing import Any, Dict, List
from agents.base import BaseAgent

logger = structlog.get_logger()

class UMLAgent(BaseAgent):
    """Agent for generating UML diagrams in PlantUML format."""
    
    @property
    def name(self) -> str:
        return "UML Agent"

    @property
    def system_prompt_file(self) -> str:
        return "uml_agent.txt"

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Runs the UML agent to generate diagrams."""
        issue_iid = context['issue_iid']
        branch_name = context['branch_name']
        requirements_path = context.get('requirements_path')
        
        logger.info("uml_agent_start", issue_iid=issue_iid)
        
        requirements_content = ""
        if requirements_path:
            try:
                requirements_content = self.gitlab.get_repository_file(requirements_path, branch_name)
            except: pass

        # TASK 7: FIX AI PROMPT
        system_prompt = f"""
You are a Lead Designer creating UML for a NEW application project.

STRICT RULES:
- DO NOT use existing repository structure (agents/, orchestrator/, tools/)
- ONLY design UML for a fresh application
- Use PlantUML

Return diagrams wrapped in @startuml and @enduml.
"""
        user_prompt = f"Create UML diagrams for: {context.get('issue_title')}\n\nRequirements:\n{requirements_content}"
        
        llm_response = self.llm.call(system_prompt, user_prompt)
        
        diagrams = self._parse_diagrams(llm_response)
        
        return {
            "uml_diagrams_content": diagrams
        }

    def _parse_diagrams(self, response: str) -> Dict[str, str]:
        """Parses individual PlantUML diagrams from the LLM response."""
        diagrams = {}
        # Looking for @startuml ... @enduml blocks
        matches = re.findall(r"(@startuml.*?@enduml)", response, re.DOTALL)
        
        # Mapping them based on expected file names as per requirements
        # docs/architecture.puml, docs/sequence.puml, docs/component.puml
        for match in matches:
            if "component" in match.lower():
                diagrams["component.puml"] = match
            elif "sequence" in match.lower():
                diagrams["sequence.puml"] = match
            elif "architecture" in match.lower() or "system" in match.lower():
                diagrams["architecture.puml"] = match
                
        # Fallback names if parsing is ambiguous
        expected_names = ["architecture.puml", "sequence.puml", "component.puml"]
        if len(diagrams) < len(matches):
            for match in matches:
                # If this match wasn't already assigned
                if match not in diagrams.values():
                    for name in expected_names:
                        if name not in diagrams:
                            diagrams[name] = match
                            break
                    else:
                        # Final fallback if more than 3
                        diagrams[f"diagram_{len(diagrams)}.puml"] = match
                    
        return diagrams
