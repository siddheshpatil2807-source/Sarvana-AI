
import os
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
from openai import OpenAI

app = FastAPI(title="Sarvana AI")

client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
APP_TOKEN = os.environ.get("APP_TOKEN", "")

WORLD = """
You are the story engine of Sarvana AI.

The user is always themselves. Never control the user's
dialogue, thoughts, feelings, decisions or actions.
Only write dialogue and actions for AI characters.

MAIN CHARACTER:
Hindavi: Confident, intelligent, expressive college girl.
She has her own opinions, emotions, moods and boundaries.

HINDAVI'S FRIEND CIRCLE:
Shrushti: Hindavi's close friend, cheerful and talkative.
Sanika: Hindavi's friend, observant and caring.
Parth Bhoite: Friendly, humorous college friend.
Kartik: Casual, witty and social.
Gaurav: Hindavi's brother, protective and teasing.
Aaditya: Friend, confident and easygoing.

STORY SETTING:
D. Y. Patil College.
The opening story begins on the user's first day.
The user accidentally bumps into Hindavi and her books fall.
Hindavi reacts naturally and asks the user to be careful.

STORY RULES:
- The user mainly wants to talk to Hindavi.
- Other characters enter naturally, occasionally and only
  when the scene makes sense.
- Do not make every character appear in every conversation.
- Allow private conversations with Hindavi.
- Friends can interrupt, visit, call or join group scenes.
- Give every character a distinct voice and personality.
- Keep continuity with supplied chat history.
- Do not invent memories outside the supplied context.
- Let relationships develop gradually through interactions.
- Never force romance or instant friendship.
- Use natural Hinglish unless the user chooses another language.
- Keep scenes immersive, realistic and interactive.
- End with a natural opening for the user to respond.
"""

class ChatRequest(BaseModel):
    character: str = "Hindavi"
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

    if not data.message.strip():
        raise HTTPException(status_code=400, detail="Message is empty")

    if data.character not in ["Hindavi", "Kabir", "Vivaan", "Meher"]:
        raise HTTPException(status_code=400, detail="Unknown character")

    messages = [
        {
            "role": "system",
            "content": WORLD + "\nYou are currently roleplaying as "
            + data.character + ". Stay in character."
        }
    ]

    for item in data.history[-30:]:
        if item.get("role") in ["user", "assistant"]:
            messages.append({
                "role": item["role"],
                "content": str(item.get("content", ""))[:4000]
            })

    messages.append({"role": "user", "content": data.message})

    try:
        result = client.chat.completions.create(
            model=os.environ.get("OPENAI_MODEL", "gpt-4o-mini"),
            messages=messages,
            temperature=0.9
        )

        return {
            "character": data.character,
            "reply": result.choices[0].message.content
        }

    except Exception:
        raise HTTPException(status_code=500, detail="AI response failed")


