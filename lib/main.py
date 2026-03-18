from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from google import genai  # <--- This is the new way to import!
from pydantic import BaseModel
import uvicorn

app = FastAPI()

# Enable CORS so your Flutter app can talk to this backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize the new Client
# Replace 'YOUR_API_KEY' with your actual key from Google AI Studio
# client = genai.Client(api_key="AIzaSyBTSelCifC9307ZkEnVg8Wv6IrB06PhdyU")
client = genai.Client(api_key="AIzaSyBOlNjkU7dJKud_W6-ElOq3iai3YVlWoTE")

class ChatRequest(BaseModel):
    prompt: str

@app.post("/chat")
async def chat_endpoint(request: ChatRequest):
    # This "System Instruction" keeps the bot focused on Ramchin Technologies
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        config={
            "system_instruction": "You are the AI Assistant for Ramchin Technologies. Be helpful and professional."
        },
        contents=request.prompt
    )

    return {"reply": response.text}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)