import express from "express";

const router = express.Router();

// GEÇİCİ HAFIZA (Veritabanı bağlanana kadar kullanıcılar burada duracak)
const users = []; 

// KAYIT OL (Register)
router.post("/register", (req, res) => {
  try {
    const { full_name, email, password } = req.body;

    // Basit doğrulama
    if (!email || !password || !full_name) {
      return res.status(400).json({ error: "Tüm alanları doldurunuz." });
    }

    // Kullanıcı zaten var mı?
    const existingUser = users.find(u => u.email === email);
    if (existingUser) {
      return res.status(400).json({ error: "Bu e-posta zaten kayıtlı." });
    }

    // Yeni kullanıcıyı kaydet
    const newUser = {
      id: Date.now().toString(), // Rastgele ID
      full_name,
      email,
      password, // Gerçek hayatta şifreler hash'lenmeli (bcrypt ile)!
    };

    users.push(newUser);
    console.log("Yeni Kayıt:", newUser);

    res.status(201).json({ message: "Kayıt başarılı", user: newUser });
  } catch (e) {
    res.status(500).json({ error: "Sunucu hatası" });
  }
});

// GİRİŞ YAP (Login)
router.post("/login", (req, res) => {
  try {
    const { email, password } = req.body;

    // Kullanıcıyı bul
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