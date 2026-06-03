-- =============================================================================
-- Additional RLS Policies for Profiles
-- =============================================================================

-- ให้แน่ใจว่าทุกคนสามารถดูโปรไฟล์คนอื่นได้ (สำหรับหน้า Discover/Feed)
CREATE POLICY "Public profiles are viewable by everyone"
ON public.profiles FOR SELECT
USING (true);

-- ให้ผู้ใช้สามารถอัปเดตโปรไฟล์ตัวเองได้เท่านั้น
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING ( auth.uid() = id )
WITH CHECK ( auth.uid() = id );

-- ให้ผู้ใช้สามารถลบโปรไฟล์ตัวเองได้ (ถ้าต้องการ)
CREATE POLICY "Users can delete own profile"
ON public.profiles FOR DELETE
USING ( auth.uid() = id );
