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
        Calls the Gemini LLM with specific rate limit handling and fallback.
        Ensures stability even when quota is exceeded.
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
            error_str = str(e)
            
            # Task 4: Rate Limit (429) Handling - Wait 60s and retry once
            if "429" in error_str or "RESOURCE_EXHAUSTED" in error_str:
                print(f"Quota exceeded (429), waiting 60 seconds... ({error_str})")
                logger.warning("llm_rate_limit_wait", delay=60)
                time.sleep(60)
                
                try:
                    response = self.client.models.generate_content(
                        model=self.model,
                        contents=truncated_prompt,
                        config=types.GenerateContentConfig(
                            system_instruction=system_prompt,
                            max_output_tokens=max_tokens or settings.AGENT_MAX_TOKENS,
                        )
                    )
                    return response.text
                except Exception as retry_error:
                    print(f"Gemini failed after retry: {str(retry_error)}")
                    return self._get_fallback_content(system_prompt)
            
            # Task 3: Safe Fallback for other errors
            print(f"Gemini failed, using fallback: {error_str}")
            logger.error("llm_call_fallback", error=error_str)
            return self._get_fallback_content(system_prompt)

    def _get_fallback_content(self, system_prompt: str) -> str:
        """Returns structured mock content based on the agent's role to prevent pipeline break."""
        system_prompt_lower = system_prompt.lower()
        
        if "product manager" in system_prompt_lower or "requirements" in system_prompt_lower:
            return "# Requirements (Fallback)\n\n## Overview\nAutomated fallback due to API quota. This is a placeholder for requirements.\n\n## Features\n- Feature 1: Placeholder\n- Feature 2: Placeholder"
        
        if "architect" in system_prompt_lower or "diagram" in system_prompt_lower:
            return "## Architecture (Fallback)\n\n@startuml\nactor User\nUser -> System : Request\nSystem -> User : Response\n@enduml"
        
        if "developer" in system_prompt_lower or "code" in system_prompt_lower:
            return "---FILE_BOUNDARY---\nFILE: src/main.py\n# Automated Fallback Code\nprint('Hello from isolated project fallback')\n---FILE_BOUNDARY---"
            
        if "uml" in system_prompt_lower:
            return "@startuml\nclass FallbackClass {\n  +id: int\n  +name: string\n}\n@enduml"

        return "Automated generated content (Fallback placeholder)"
