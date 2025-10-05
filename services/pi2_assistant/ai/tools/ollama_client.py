import httpx

class OllamaClient:
    def __init__(self, model: str, temperature: float = 0.3, max_tokens: int = 160, base_url: str = "http://127.0.0.1:11434"):
        self.model = model
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.base_url = base_url.rstrip("/")

    def generate(self, prompt: str, json_mode: bool = True) -> str:
        payload = {
            "model": self.model,
            "prompt": prompt,
            "options": {
                "temperature": self.temperature,
                "num_predict": self.max_tokens,
                "repeat_penalty": 1.2,
                "repeat_last_n": 64,
                "stop": ["OBS_TOOL", "USER:", "ASSISTANT:", "TOOL:"]
            },
            "stream": False
        }
        if json_mode:
            payload["format"] = "json"
        with httpx.Client(timeout=60) as client:
            r = client.post(f"{self.base_url}/api/generate", json=payload)
            r.raise_for_status()
            return r.json().get("response", "")