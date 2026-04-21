import { supabase } from "../supabase.js";

const DEFAULT_BUCKET = process.env.SUPABASE_FIELD_IMAGES_BUCKET || "field-images";

const sanitizeSegment = (value) =>
  (value || "unknown")
    .toLowerCase()
    .replace(/[^a-z0-9._-]/g, "-")
    .replace(/-+/g, "-")
    .slice(0, 80);

const getExtensionFromFileName = (fileName) => {
  const ext = (fileName || "").split(".").pop()?.toLowerCase();
  if (!ext) return "jpg";
  if (["jpg", "jpeg", "png", "webp"].includes(ext)) return ext;
  return "jpg";
};

const contentTypeFromExtension = (ext) => {
  if (ext == "png") return "image/png";
  if (ext == "webp") return "image/webp";
  return "image/jpeg";
};

export const addField = async (user_email, name, area, coordinates, crop, image_url) => {
  const payload = { user_email, name, area, coordinates };
  if (crop) payload.crop = crop;
  if (image_url) payload.image_url = image_url;

  let { data, error } = await supabase
    .from("fields")
    .insert([payload])
    .select();

  // If DB schema doesn't yet include crop/image fields, retry with base payload.
  if (error && (payload.crop || payload.image_url)) {
    const fallback = await supabase
      .from("fields")
      .insert([{ user_email, name, area, coordinates }])
      .select();

    if (fallback.error) throw fallback.error;
    return fallback.data[0];
  }

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

export const deleteField = async (fieldId) => {
  const { data, error } = await supabase
    .from("fields")
    .delete()
    .eq("id", fieldId);

  if (error) throw error;
  return data;
};

export const uploadFieldImage = async ({ user_email, image_base64, file_name }) => {
  console.log('[field.service.uploadFieldImage] start', {
    user_email,
    file_name,
    imageBase64Length: image_base64?.length || 0,
  });

  const metaMatch = image_base64.match(/^data:(image\/[a-zA-Z0-9.+-]+);base64,/);
  const hasDataUrlPrefix = Boolean(metaMatch);
  const normalized = hasDataUrlPrefix ? image_base64.split(",").slice(1).join(",") : image_base64;

  const fileBuffer = Buffer.from(normalized, "base64");
  if (!fileBuffer.length) {
    throw new Error("Gecersiz gorsel verisi");
  }

  const extFromData = metaMatch?.[1]?.split("/")?.[1]?.toLowerCase();
  const extension = extFromData || getExtensionFromFileName(file_name);
  const contentType = contentTypeFromExtension(extension);
  const safeEmail = sanitizeSegment(user_email);
  const safeName = sanitizeSegment(file_name || "field-image");
  const path = `${safeEmail}/${Date.now()}-${Math.floor(Math.random() * 1e6)}-${safeName}.${extension}`;

  const { error: uploadError } = await supabase.storage
    .from(DEFAULT_BUCKET)
    .upload(path, fileBuffer, {
      contentType,
      upsert: false,
    });

  if (uploadError) {
    console.error('[field.service.uploadFieldImage] supabase upload error', {
      message: uploadError.message,
      statusCode: uploadError.statusCode,
      name: uploadError.name,
      details: uploadError.details,
      hint: uploadError.hint,
    });
    throw uploadError;
  }

  const { data } = supabase.storage.from(DEFAULT_BUCKET).getPublicUrl(path);
  console.log('[field.service.uploadFieldImage] success', { path, publicUrl: data.publicUrl });
  return data.publicUrl;
};
