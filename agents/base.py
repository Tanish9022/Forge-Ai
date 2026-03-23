import os
from abc import ABC, abstractmethod
from typing import Any, Dict
from tools.gitlab_tools import GitLabTools
from tools.llm_tools import LLMClient
from orchestrator.state import StateManagerInterface

class BaseAgent(ABC):
    """Abstract base class for all SDLC agents."""
    
    def __init__(self, gitlab: GitLabTools, llm: LLMClient, state_manager: StateManagerInterface):
        self.gitlab = gitlab
        self.llm = llm
        self.state_manager = state_manager

    @property
    @abstractmethod
    def name(self) -> str:
        """The agent's display name."""
        pass

    @property
    @abstractmethod
    def system_prompt_file(self) -> str:
        """The filename of the system prompt in the prompts/ directory."""
        pass

    def load_prompt(self) -> str:
        """Loads the system prompt from the file system."""
        prompt_path = os.path.join(os.path.dirname(__file__), '..', 'prompts', self.system_prompt_file)
        with open(prompt_path, 'r', encoding='utf-8-sig') as f:
            return f.read()

    @abstractmethod
    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Main execution logic for the agent."""
        pass

    def update_context(self, project_id: int, issue_id: int, data: Dict[str, Any]) -> None:
        """Convenience method to update state manager context."""
        self.state_manager.update_context(project_id, issue_id, data)
