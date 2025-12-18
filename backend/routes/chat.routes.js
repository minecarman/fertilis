import express from "express";

const router = express.Router();

router.post("/", async (req, res) => {
  try {
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({ error: "Message is required" });
    }

    const response = await fetch(
      "https://openrouter.ai/api/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "http://localhost",
          "X-Title": "Fertilis AI"
        },
        body: JSON.stringify({
          model: "meta-llama/llama-3.3-70b-instruct:free",
          messages: [
            {
              role: "system",
              content:
                "You are Fertilis AI, an advanced chatbot designed to assist users with information related to agriculture, weather, farming and related topics. Provide accurate, empathetic, and helpful responses."
            },
            {
              role: "user",
              content: message
            }
          ]
        })
      }
    );

    const data = await response.json();

    const reply =
      data.choices?.[0]?.message?.content || "Cevap alınamadı";

    res.json({ reply });

  } catch (err) {
    console.error("OPENROUTER ERROR:", err);
    res.status(500).json({
      error: "OpenRouter error",
      details: err.message
    });
  }
});

export default router;
