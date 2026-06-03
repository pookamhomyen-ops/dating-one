-- Secret Photos Bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('secret-photos', 'secret-photos', true) ON CONFLICT DO NOTHING;

CREATE POLICY "Users can upload own secret photos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'secret-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can delete own secret photos" ON storage.objects FOR DELETE USING (bucket_id = 'secret-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Anyone can view secret photos" ON storage.objects FOR SELECT USING (bucket_id = 'secret-photos');

-- Secret Photos Table
CREATE TABLE IF NOT EXISTS public.secret_photos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    storage_path text NOT NULL,
    public_url text NOT NULL,
    sort_order integer NOT NULL DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.secret_photos ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can insert their own secret photos" ON public.secret_photos
    FOR INSERT WITH CHECK (auth.uid() = profile_id);
CREATE POLICY "Users can update their own secret photos" ON public.secret_photos
    FOR UPDATE USING (auth.uid() = profile_id);
CREATE POLICY "Users can delete their own secret photos" ON public.secret_photos
    FOR DELETE USING (auth.uid() = profile_id);
CREATE POLICY "Anyone can view secret photos" ON public.secret_photos
    FOR SELECT USING (true);
