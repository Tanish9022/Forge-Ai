import time
import asyncio
import structlog
from google import genai
from google.genai import types
from typing import Optional
from config import settings, GEMINI_API_KEY

logger = structlog.get_logger()

class LLMClient:
    """Wrapper for Google GenAI SDK with retries and logging."""
    
    def __init__(self, api_key: str = GEMINI_API_KEY, model: str = settings.AGENT_MODEL):
        self.client = genai.Client(api_key=api_key)
        self.model = model

    def call(self, system_prompt: str, user_prompt: str, max_tokens: Optional[int] = None) -> str:
        """
        Calls the Gemini LLM with fast fallback.
        Ensures stability even when quota is exceeded or API fails.
        """
        # Task 5: Reduce token usage/prompt size
        truncated_prompt = user_prompt[:2000]
        
        try:
            # First Attempt
            response = self.client.models.generate_content(
                model=self.model,
                contents=truncated_prompt,
                config=types.GenerateContentConfig(
                    system_instruction=system_prompt,
                    max_output_tokens=max_tokens or settings.AGENT_MAX_TOKENS,
                )
            )
            logger.info("llm_call_success", model=self.model)
            return response.text

        except Exception as e:
            # TASK 8 & 9: FAST FALLBACK ON ERROR / QUOTA
            error_str = str(e)
            print(f"Gemini failed, using fallback: {error_str}")
            logger.error("llm_call_fallback_triggered", error=error_str)
            
            return self._get_fallback_content(system_prompt)

    def _get_fallback_content(self, system_prompt: str) -> str:
        """Returns structured mock content based on the agent's role to prevent pipeline break."""
        system_prompt_lower = system_prompt.lower()
        
        if "product manager" in system_prompt_lower or "requirements" in system_prompt_lower:
            return "# Requirements (Fallback)\n\n## Overview\nAutomated fallback due to API limit. This project provides basic functionality.\n\n## Features\n- API Backend\n- Frontend UI\n- Database Integration"
        
        if "architect" in system_prompt_lower or "diagram" in system_prompt_lower:
            return "## Architecture (Fallback)\n\n@startuml\nactor User\nUser -> System : Interaction\nSystem -> User : Response\n@enduml"
        
        if "developer" in system_prompt_lower or "code" in system_prompt_lower:
            return "---FILE_BOUNDARY---\nFILE: backend/main.py\n# Automated Fallback Code\nfrom fastapi import FastAPI\napp = FastAPI()\n@app.get('/')\ndef read_root(): return {'status': 'ok'}\n---FILE_BOUNDARY---\nFILE: README.md\n# New Project\nGenerated via fallback.\n---FILE_BOUNDARY---"
            
        if "uml" in system_prompt_lower:
            return "@startuml\nclass Project {\n  +id: int\n  +title: string\n}\n@enduml"

        return "Automated generated content (Fallback placeholder)"
