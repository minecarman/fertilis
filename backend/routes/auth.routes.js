import express from "express";

const router = express.Router();

// çakma database
const users = []; 

// kayıt
router.post("/register", (req, res) => {
  try {
    const { full_name, email, password } = req.body;

    // boş alan kontrol
    if (!email || !password || !full_name) {
      return res.status(400).json({ error: "Tüm alanları doldurunuz." });
    }

    // mail kontrol
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: "Geçersiz e-posta formatı." });
    }

    // şifre kontrol
    if (password.length < 6) {
      return res.status(400).json({ error: "Şifre en az 6 karakter olmalıdır." });
    }

    // kayıtlı mı kontrol
    const existingUser = users.find(u => u.email === email);
    if (existingUser) {
      return res.status(400).json({ error: "Bu e-posta zaten kayıtlı." });
    }

    const newUser = {
      id: Date.now().toString(),
      full_name,
      email,
      password, 
    };

    users.push(newUser);
    console.log("Yeni Kayıt:", newUser);

    res.status(201).json({ message: "Kayıt başarılı", user: newUser });
  } catch (e) {
    res.status(500).json({ error: "Sunucu hatası" });
  }
});

// GİRİŞ YAP
router.post("/login", (req, res) => {
  try {
    const { email, password } = req.body;

    const user = users.find(u => u.email === email && u.password === password);

    if (user) {
      res.json({ 
        success: true, 
        message: "Giriş başarılı", 
        user: { id: user.id, full_name: user.full_name, email: user.email }
      });
    } else {
      res.status(401).json({ error: "Hatalı e-posta veya şifre" });
    }
  } catch (e) {
    res.status(500).json({ error: "Sunucu hatası" });
  }
});

export default router;