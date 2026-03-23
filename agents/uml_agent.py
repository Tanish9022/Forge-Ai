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
        project_id = context['project_id']
        issue_iid = context['issue_iid']
        branch_name = context['branch_name']
        requirements_path = context.get('requirements_path', 'docs/requirements.md')
        architecture_path = context.get('architecture_path', 'docs/architecture.md')
        
        logger.info("uml_agent_start", issue_iid=issue_iid)
        
        # Gather information from previous steps
        requirements_content = ""
        try:
            requirements_content = self.gitlab.get_repository_file(requirements_path, branch_name)
        except:
            logger.warning("uml_agent_requirements_not_found", path=requirements_path)

        architecture_content = ""
        try:
            # Check if architect agent provides a different path or if we should just try to read it
            # Architecture agent usually writes to docs/diagrams/ so we might need a general arch doc
            # but for now let's assume we can get some context.
            architecture_content = self.gitlab.get_repository_file(architecture_path, branch_name)
        except:
            logger.warning("uml_agent_architecture_not_found", path=architecture_path)
            
        system_prompt = self.load_prompt()
        user_prompt = f"Feature Requirements:\n{requirements_content}\n\nArchitecture Design:\n{architecture_content}"
        
        llm_response = self.llm.call(system_prompt, user_prompt)
        
        diagrams = self._parse_diagrams(llm_response)
        
        diagram_paths = []
        for file_name, content in diagrams.items():
            path = f"docs/{file_name}"
            self.gitlab.commit_file(
                branch=branch_name,
                file_path=path,
                content=content,
                commit_message=f"docs: generate {file_name} for issue #{issue_iid}"
            )
            diagram_paths.append(path)
            
        summary = f"UML diagrams generated for issue #{issue_iid}:\n"
        for path in diagram_paths:
            summary += f"- {path}\n"
        
        self.gitlab.post_issue_comment(issue_iid, summary)
        
        logger.info("uml_agent_complete", diagram_count=len(diagram_paths))
        
        return {
            "uml_diagram_paths": diagram_paths
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
