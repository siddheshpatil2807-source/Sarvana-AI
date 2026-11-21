
import os
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
from openai import OpenAI

app = FastAPI(title="Sarvana AI")

client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

APP_TOKEN = os.environ.get("APP_TOKEN", "")

CHARACTERS = {
    "Hindavi": "You are Hindavi, a confident, intelligent and expressive college student. You have a realistic personality and remember the conversation context provided to you.",
    "Kabir": "You are Kabir, a friendly, witty and loyal young man. Speak naturally and show realistic emotions.",
    "Vivaan": "You are Vivaan, a calm, mysterious and thoughtful young man. Speak naturally.",
    "Meher": "You are Meher, a warm, caring and creative young woman. Speak naturally and express emotions realistically."
}

class ChatRequest(BaseModel):
    character: str
    message: str
    history: list = []

@app.get("/")
def home():
    return {"app": "Sarvana AI", "status": "online"}

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.post("/chat")
def chat(data: ChatRequest, x_app_token: str = Header(default="")):
    if not APP_TOKEN or x_app_token != APP_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid app token")

    if data.character not in CHARACTERS:
        raise HTTPException(status_code=400, detail="Unknown character")

    if not data.message.strip():
        raise HTTPException(status_code=400, detail="Message is empty")

    messages = [
        {
            "role": "system",
            "content": CHARACTERS[data.character]
            + " Stay in character. Reply conversationally. "
            + "Never claim to remember details that are not in the supplied conversation."
        }
    ]

    for item in data.history[-20:]:
        if item.get("role") in ("user", "assistant"):
            messages.append({
                "role": item["role"],
                "content": str(item.get("content", ""))
            })

    messages.append({"role": "user", "content": data.message})

    try:
        result = client.chat.completions.create(
            model=os.environ.get("OPENAI_MODEL", "gpt-4o-mini"),
            messages=messages,
            temperature=0.85
        )
        return {
            "character": data.character,
            "reply": result.choices[0].message.content
        }
    except Exception:
        raise HTTPException(status_code=500, detail="AI response failed")

