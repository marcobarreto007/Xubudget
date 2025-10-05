from langdetect import detect, DetectorFactory
DetectorFactory.seed = 0

def detect_lang(text: str, default: str = "pt") -> str:
    try:
        code = detect(text or "")
        return (code or default).split("-")[0].lower()
    except Exception:
        return default

def lang_name(code: str) -> str:
    MAP = {
        "pt": "português do Brasil",
        "en": "inglês", 
        "es": "espanhol",
        "fr": "francês",
        "de": "alemão",
        "it": "italiano",
        "hi": "hindi",
        "ar": "árabe",
        "zh": "chinês",
        "ja": "japonês",
        "ko": "coreano",
    }
    return MAP.get(code, code)
