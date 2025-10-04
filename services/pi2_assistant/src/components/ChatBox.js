import React, { useEffect, useState } from "react";
import axios from "axios";
import "./ChatBox.css";

const API_BASE = "http://127.0.0.1:5002/api";
const FEMALE_VOICE_HINTS = [
  "female",
  "woman",
  "amy",
  "aria",
  "ava",
  "emma",
  "olivia",
  "samantha",
  "joanna",
  "sofia",
  "victoria",
  "luna",
  "allison",
  "karen",
  "lisa"
];

const pickEnglishFemaleVoice = (voices) => {
  if (!Array.isArray(voices) || voices.length === 0) return null;
  const english = voices.filter((voice) => (voice?.lang || "").toLowerCase().startsWith("en"));
  const preferred = english.find((voice) => {
    const name = (voice?.name || "").toLowerCase();
    return FEMALE_VOICE_HINTS.some((hint) => name.includes(hint));
  });
  return preferred || english[0] || voices[0] || null;
};

function ChatBox() {
  const [messages, setMessages] = useState([
    {
      text: "Hi! I'm Xuzinha, your budget assistant. How can I help you today?",
      sender: "ai"
    }
  ]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [ttsEnabled, setTtsEnabled] = useState(false);
  const [voice, setVoice] = useState(null);

  useEffect(() => {
    if (typeof window === "undefined" || !window.speechSynthesis) return;

    const assignVoice = () => {
      try {
        const available = window.speechSynthesis.getVoices?.() || [];
        if (!available.length) return;
        setVoice(pickEnglishFemaleVoice(available));
      } catch (error) {
        console.debug("[ChatBox] Failed selecting voice", error);
      }
    };

    assignVoice();
    window.speechSynthesis.onvoiceschanged = assignVoice;
    return () => {
      if (window.speechSynthesis.onvoiceschanged === assignVoice) {
        window.speechSynthesis.onvoiceschanged = null;
      }
    };
  }, []);

  const speak = (text) => {
    if (!ttsEnabled) return;
    if (!text) return;
    if (typeof window === "undefined" || !window.speechSynthesis) return;

    try {
      const utterance = new SpeechSynthesisUtterance(text);
      if (voice) {
        utterance.voice = voice;
        utterance.lang = voice.lang;
      } else {
        utterance.lang = "en-US";
      }
      window.speechSynthesis.cancel();
      window.speechSynthesis.speak(utterance);
    } catch (error) {
      console.debug("[ChatBox] TTS error", error);
    }
  };

  const sendMessage = async (event) => {
    event.preventDefault();
    const payload = input.trim();
    if (!payload) return;

    const userMessage = { text: payload, sender: "user" };
    setMessages((prev) => [...prev, userMessage]);
    setInput("");
    setLoading(true);

    try {
      const response = await axios.post(`${API_BASE}/chat`, { message: payload });
      const reply = response?.data?.response ?? "Ok!";
      const aiMessage = { text: reply, sender: "ai" };
      setMessages((prev) => [...prev, aiMessage]);
      speak(reply);
    } catch (error) {
      const fallback = {
        text: "Sorry, I had trouble processing that. Please try again.",
        sender: "ai"
      };
      setMessages((prev) => [...prev, fallback]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="chatbox">
      <div
        className="chat-header"
        style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
          <span className="chat-emoji" aria-hidden="true">
            AI
          </span>
          <h3>Chat with Xuzinha</h3>
        </div>
        <button
          type="button"
          onClick={() => setTtsEnabled((prev) => !prev)}
          style={{ background: "none", border: "none", fontSize: "20px", cursor: "pointer" }}
          title={ttsEnabled ? "Turn voice off" : "Turn voice on"}
        >
          {ttsEnabled ? "??" : "??"}
        </button>
      </div>
      <div className="chat-messages">
        {messages.map((message, index) => (
          <div key={`${message.sender}-${index}`} className={`message ${message.sender}`}>
            {message.sender === "ai" && (
              <span className="avatar" aria-hidden="true">
                AI
              </span>
            )}
            <div className="bubble">{message.text}</div>
            {message.sender === "user" && (
              <span className="avatar" aria-hidden="true">
                You
              </span>
            )}
          </div>
        ))}
        {loading && (
          <div className="message ai">
            <span className="avatar" aria-hidden="true">
              AI
            </span>
            <div className="bubble typing">Typing...</div>
          </div>
        )}
      </div>
      <form onSubmit={sendMessage} className="chat-input">
        <input
          type="text"
          value={input}
          onChange={(event) => setInput(event.target.value)}
          placeholder="Ask me anything about your budget..."
          disabled={loading}
        />
        <button type="submit" disabled={loading}>
          Send
        </button>
      </form>
    </div>
  );
}

export default ChatBox;
