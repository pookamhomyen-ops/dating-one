CREATE TABLE IF NOT EXISTS public.profile_photos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    storage_path text NOT NULL,
    public_url text NOT NULL,
    sort_order integer NOT NULL DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.profile_photos ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can insert their own profile photos" ON public.profile_photos
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update their own profile photos" ON public.profile_photos
    FOR UPDATE USING (auth.uid() = profile_id);

CREATE POLICY "Users can delete their own profile photos" ON public.profile_photos
    FOR DELETE USING (auth.uid() = profile_id);

CREATE POLICY "Anyone can view profile photos" ON public.profile_photos
    FOR SELECT USING (true);
