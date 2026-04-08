export const fetchChatCompletion = async (message) => {
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
        model: "meta-llama/llama-3.3-70b-instruct",
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

  return response;
};
