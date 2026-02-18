import express from "express";
import { supabase } from "../supabase.js";

const router = express.Router();

router.post("/add", async (req, res) => {
  try {
    const { user_email, name, area, coordinates } = req.body;

    if (!user_email || !coordinates) {
      return res.status(400).json({ error: "Eksik bilgi." });
    }

    const { data, error } = await supabase
      .from("fields")
      .insert([{ user_email, name, area, coordinates }])
      .select();

    if (error) throw error;

    res.status(201).json({ message: "Tarla kaydedildi!", field: data[0] });
  } catch (e) {
    console.error("Tarla Kayıt Hatası:", e);
    res.status(500).json({ error: e.message });
  }
});

router.get("/:email", async (req, res) => {
  try {
    const { email } = req.params;
    const { data, error } = await supabase
      .from("fields")
      .select("*")
      .eq("user_email", email);

    if (error) throw error;

    res.json(data);
  } catch (e) {
    console.error("Tarla Okuma Hatası:", e);
    res.status(500).json({ error: e.message });
  }
});

export default router;