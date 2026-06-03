-- =============================================================================
-- Setup Storage for Profile Photos
-- =============================================================================

-- 1. สร้าง Bucket สำหรับเก็บรูปโปรไฟล์ (ถ้ายังไม่มี)
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. ตั้งค่า RLS สำหรับ Storage
-- ให้ทุกคนอ่านรูปได้
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'profile-photos' );

-- ให้เจ้าของโปรไฟล์อัปโหลดรูปได้
CREATE POLICY "Users can upload their own photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile-photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- ให้เจ้าของโปรไฟล์ลบรูปตัวเองได้
CREATE POLICY "Users can delete their own photos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile-photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
