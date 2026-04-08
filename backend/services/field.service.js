import { supabase } from "../supabase.js";

export const addField = async (user_email, name, area, coordinates) => {
  const { data, error } = await supabase
    .from("fields")
    .insert([{ user_email, name, area, coordinates }])
    .select();

  if (error) throw error;
  return data[0];
};

export const getFieldsByUserEmail = async (email) => {
  const { data, error } = await supabase
    .from("fields")
    .select("*")
    .eq("user_email", email);

  if (error) throw error;
  return data;
};
