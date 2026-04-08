import { supabase } from "../supabase.js";

export const registerUser = async (full_name, email, password) => {
  const { data: existingUser } = await supabase
    .from("users")
    .select("email")
    .eq("email", email)
    .single();

  if (existingUser) {
    throw new Error("Bu e-posta zaten kayıtlı.");
  }

  const { data, error } = await supabase
    .from("users")
    .insert([{ full_name, email, password }])
    .select();

  if (error) {
    throw new Error("Kayıt sırasında hata oluştu.");
  }

  return data[0];
};

export const loginUser = async (email, password) => {
  const { data: user, error } = await supabase
    .from("users")
    .select("*")
    .eq("email", email)
    .eq("password", password)
    .single();

  if (error || !user) {
    throw new Error("E-posta veya şifre hatalı.");
  }

  const { password: _, ...userWithoutPassword } = user;
  return userWithoutPassword;
};

export const updateUserProfile = async (old_email, new_email, full_name) => {
  if (old_email !== new_email) {
    const { data: existingUser } = await supabase
      .from("users")
      .select("email")
      .eq("email", new_email)
      .single();

    if (existingUser) {
      throw new Error("Bu e-posta başka bir hesap tarafından kullanılıyor.");
    }
  }

  const { data: updatedUser, error } = await supabase
    .from("users")
    .update({ email: new_email, full_name: full_name })
    .eq("email", old_email)
    .select()
    .single();

  if (error || !updatedUser) {
    throw new Error("Profil güncellenirken bir hata oluştu.");
  }

  const { password: _, ...userWithoutPassword } = updatedUser;
  return userWithoutPassword;
};
