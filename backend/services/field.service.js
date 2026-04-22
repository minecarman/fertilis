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

const buildFieldImagePath = (userEmail, fieldId) => {
  const safeEmail = sanitizeSegment(userEmail);
  return `${safeEmail}/field-${fieldId}`;
};

const buildFieldImagePublicUrl = (userEmail, fieldId) => {
  const supabaseUrl = process.env.SUPABASE_URL;
  if (!supabaseUrl || !fieldId) return null;
  const base = supabaseUrl.replace(/\/$/, "");
  return `${base}/storage/v1/object/public/${DEFAULT_BUCKET}/${buildFieldImagePath(userEmail, fieldId)}`;
};

const removeFieldImages = async (userEmail, fieldId) => {
  const folderPath = sanitizeSegment(userEmail);
  const prefix = `field-${fieldId}`;

  const { data: objects, error: listError } = await supabase.storage
    .from(DEFAULT_BUCKET)
    .list(folderPath);

  if (listError) {
    throw listError;
  }

  const pathsToDelete = (objects || [])
    .map((object) => object.name)
    .filter((name) => name.startsWith(prefix))
    .map((name) => `${folderPath}/${name}`);

  if (pathsToDelete.length === 0) return;

  const { error: removeError } = await supabase.storage
    .from(DEFAULT_BUCKET)
    .remove(pathsToDelete);

  if (removeError) {
    throw removeError;
  }

  console.log("[field.service.deleteField] storage images removed", {
    userEmail,
    fieldId,
    pathsToDelete,
  });
};

export const addField = async (user_email, name, area, coordinates, crop, image_url) => {
  const payload = { user_email, name, area, coordinates };
  if (crop) payload.crop = crop;
  if (image_url) payload.image_url = image_url;

  console.log("[field.service.addField] insert start", {
    user_email,
    hasCrop: Boolean(crop),
    hasImageUrl: Boolean(image_url),
  });

  let { data, error } = await supabase
    .from("fields")
    .insert([payload])
    .select();

  if (error && (payload.crop || payload.image_url)) {
    console.warn("[field.service.addField] full payload insert failed, trying fallbacks", {
      message: error.message,
      details: error.details,
      hint: error.hint,
    });

    // Try preserving image_url first (common case: crop column missing in schema).
    if (payload.image_url) {
      const imageFallback = await supabase
        .from("fields")
        .insert([{ user_email, name, area, coordinates, image_url }])
        .select();

      if (!imageFallback.error) {
        console.warn("[field.service.addField] fallback succeeded with image_url only");
        return imageFallback.data[0];
      }
    }

    // Try preserving crop only.
    if (payload.crop) {
      const cropFallback = await supabase
        .from("fields")
        .insert([{ user_email, name, area, coordinates, crop }])
        .select();

      if (!cropFallback.error) {
        console.warn("[field.service.addField] fallback succeeded with crop only");
        return cropFallback.data[0];
      }
    }

    // Last resort: minimal payload.
    const baseFallback = await supabase
      .from("fields")
      .insert([{ user_email, name, area, coordinates }])
      .select();

    if (baseFallback.error) throw baseFallback.error;
    console.warn("[field.service.addField] fallback succeeded with base payload only (no crop/image)");
    return baseFallback.data[0];
  }

  if (error) throw error;
  console.log("[field.service.addField] insert success");
  return data[0];
};

export const getFieldsByUserEmail = async (email) => {
  const { data, error } = await supabase
    .from("fields")
    .select("*")
    .eq("user_email", email);

  if (error) throw error;

  // fields table has no image_url column; expose deterministic public url instead.
  return (data || []).map((row) => ({
    ...row,
    image_url: buildFieldImagePublicUrl(row.user_email, row.id),
  }));
};

export const deleteField = async (fieldId) => {
  const { data: fieldRows, error: getError } = await supabase
    .from("fields")
    .select("id, user_email")
    .eq("id", fieldId)
    .limit(1);

  if (getError) throw getError;

  const field = fieldRows?.[0];
  if (field?.id) {
    try {
      await removeFieldImages(field.user_email, field.id);
    } catch (storageError) {
      console.warn("[field.service.deleteField] storage cleanup failed, continuing with DB delete", {
        fieldId,
        message: storageError.message,
      });
    }
  }

  const { data, error } = await supabase
    .from("fields")
    .delete()
    .eq("id", fieldId)
    .select("id");

  if (error) throw error;
  return data;
};

export const updateFieldName = async ({ fieldId, name }) => {
  const trimmedName = (name || "").trim();
  if (!trimmedName) {
    throw new Error("Tarla adı boş olamaz");
  }

  const { data, error } = await supabase
    .from("fields")
    .update({ name: trimmedName })
    .eq("id", fieldId)
    .select("*")
    .single();

  if (error) throw error;
  return {
    ...data,
    image_url: buildFieldImagePublicUrl(data.user_email, data.id),
  };
};

export const uploadFieldImage = async ({ user_email, image_base64, file_name, field_id }) => {
  console.log('[field.service.uploadFieldImage] start', {
    user_email,
    file_name,
    field_id,
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
  const path = field_id
    ? buildFieldImagePath(user_email, field_id)
    : `${sanitizeSegment(user_email)}/${Date.now()}-${Math.floor(Math.random() * 1e6)}-${sanitizeSegment(file_name || "field-image")}.${extension}`;

  const { error: uploadError } = await supabase.storage
    .from(DEFAULT_BUCKET)
    .upload(path, fileBuffer, {
      contentType,
      upsert: Boolean(field_id),
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
