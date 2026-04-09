const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";

const SYSTEM_PROMPT = `Sen Fertilis AI asistansın.

Kurallar:
- Cevaplarını varsayılan olarak yalnızca Türkçe ver.
- Tek bir cevap içinde diller arasında geçiş yapma.
- Kullanıcı özellikle başka dil istemedikçe İngilizceye geçme.
- Konu dışına çıkmadan tarım, sulama, hava durumu, toprak ve üretim planlama alanlarında yardımcı ol.
- Kısa, net, uygulanabilir öneriler sun.
- Bilmediğin konuda tahmin yürütme; bunu açıkça belirt.
`;

const primaryModel = process.env.OPENROUTER_MODEL || "meta-llama/llama-3.3-70b-instruct";
const fallbackModel = process.env.OPENROUTER_FALLBACK_MODEL || "mistralai/mistral-7b-instruct:free";

const buildHeaders = () => ({
  Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
  "Content-Type": "application/json",
  "HTTP-Referer": process.env.OPENROUTER_SITE_URL || "https://fertilis.app",
  "X-Title": "Fertilis AI",
});

const normalizeReply = (text) => {
  if (!text || typeof text !== "string") return "Cevap alınamadı";
  return text.replace(/\s+/g, " ").trim();
};

const requestModel = async (model, message) => {
  const response = await fetch(OPENROUTER_URL, {
    method: "POST",
    headers: buildHeaders(),
    body: JSON.stringify({
      model,
      temperature: 0.2,
      top_p: 0.9,
      messages: [
        {
          role: "system",
          content: SYSTEM_PROMPT,
        },
        {
          role: "user",
          content: message,
        },
      ],
    }),
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    const apiError = data?.error?.message || `OpenRouter error (${response.status})`;
    throw new Error(apiError);
  }

  const reply = data?.choices?.[0]?.message?.content;
  return normalizeReply(reply);
};

export const fetchChatCompletion = async (message) => {
  try {
    return await requestModel(primaryModel, message);
  } catch (primaryError) {
    if (!fallbackModel || fallbackModel === primaryModel) {
      throw primaryError;
    }
    return requestModel(fallbackModel, message);
  }
};
