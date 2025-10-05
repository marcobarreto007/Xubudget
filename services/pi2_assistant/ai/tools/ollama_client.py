import httpx

class OllamaClient:
    def __init__(self, model: str, temperature: float = 0.3, max_tokens: int = 160, base_url: str = "http://127.0.0.1:11434", repeat_penalty: float = 1.2, stop: list = None):
        self.model = model
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.base_url = base_url.rstrip("/")
        self.repeat_penalty = repeat_penalty
        self.stop = stop if stop is not None else ["OBS_TOOL", "USER:", "ASSISTANT:", "TOOL:"]

    def generate(self, prompt: str, json_mode: bool = True) -> str:
        payload = {
            "model": self.model,
            "prompt": prompt,
            "options": {
                "temperature": self.temperature,
                "num_predict": self.max_tokens,
                "repeat_penalty": self.repeat_penalty,
                "repeat_last_n": 64,
                "stop": self.stop
            },
            "stream": False
        }
        if json_mode:
            payload["format"] = "json"
        with httpx.Client(timeout=60) as client:
            r = client.post(f"{self.base_url}/api/generate", json=payload)
            r.raise_for_status()
            return r.json().get("response", "")