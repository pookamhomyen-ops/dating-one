ALTER TABLE public.profile_photos ADD COLUMN IF NOT EXISTS is_primary boolean DEFAULT false;
ALTER TABLE public.secret_photos ADD COLUMN IF NOT EXISTS is_primary boolean DEFAULT false;
