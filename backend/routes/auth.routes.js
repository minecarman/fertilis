import express from "express";
import { supabase } from "../supabase.js";

const router = express.Router();

router.post("/register", async (req, res) => {
  try {
    const { full_name, email, password } = req.body;


    if (!email || !password || !full_name) {
      return res.status(400).json({ error: "Tüm alanları doldurunuz." });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: "Şifre en az 6 karakter olmalıdır." });
    }

    const { data: existingUser } = await supabase
      .from("users")
      .select("email")
      .eq("email", email)
      .single();

    if (existingUser) {
      return res.status(400).json({ error: "Bu e-posta zaten kayıtlı." });
    }

    const { data, error } = await supabase
      .from("users")
      .insert([{ full_name, email, password }])
      .select();

    if (error) {
      console.error("Supabase Hatası:", error);
      return res.status(500).json({ error: "Kayıt sırasında hata oluştu." });
    }

    console.log("yeni kullanıcı:", email);
    res.status(201).json({ message: "Kayıt başarılı", user: data[0] });

  } catch (e) {
    console.error("Sunucu Hatası:", e);
    res.status(500).json({ error: "Sunucu hatası" });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "E-posta ve şifre gereklidir." });
    }

    const { data: user, error } = await supabase
      .from("users")
      .select("*")
      .eq("email", email)
      .eq("password", password)
      .single();

    if (error || !user) {
      return res.status(401).json({ error: "E-posta veya şifre hatalı." });
    }

    console.log("Giriş Başarılı:", user.full_name);
    
    const { password: _, ...userWithoutPassword } = user; 

    res.json({ 
      message: "Giriş başarılı", 
      user: userWithoutPassword 
    });

  } catch (e) {
    console.error("Login Hatası:", e);
    res.status(500).json({ error: "Sunucu hatası" });
  }
});

router.put("/profile", async (req, res) => {
  try {
    const { old_email, new_email, full_name } = req.body;

    if (!old_email || !new_email || !full_name) {
      return res.status(400).json({ error: "Tüm alanlar gereklidir." });
    }

    // Check if new email is already used by someone else
    if (old_email !== new_email) {
      const { data: existingUser } = await supabase
        .from("users")
        .select("email")
        .eq("email", new_email)
        .single();
      
      if (existingUser) {
        return res.status(400).json({ error: "Bu e-posta başka bir hesap tarafından kullanılıyor." });
      }
    }

    const { data: updatedUser, error } = await supabase
      .from("users")
      .update({ email: new_email, full_name: full_name })
      .eq("email", old_email)
      .select()
      .single();

    if (error || !updatedUser) {
      console.error("Supabase Error:", error);
      return res.status(500).json({ error: "Profil güncellenirken bir hata oluştu." });
    }

    const { password: _, ...userWithoutPassword } = updatedUser;
    
    res.json({ message: "Profil başarıyla güncellendi.", user: userWithoutPassword });
  } catch (e) {
    console.error("Profil güncelleme hatası:", e);
    res.status(500).json({ error: "Sunucu hatası" });
  }
});

export default router;