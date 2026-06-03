CREATE TABLE IF NOT EXISTS public.secret_photos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id      UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  storage_path    TEXT NOT NULL,
  public_url      TEXT,
  sort_order      SMALLINT NOT NULL DEFAULT 0,
  is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (profile_id, sort_order)
);

CREATE INDEX IF NOT EXISTS idx_secret_photos_profile ON public.secret_photos (profile_id, sort_order);

ALTER TABLE public.secret_photos ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "Users can view own secret photos" ON public.secret_photos FOR SELECT USING (auth.uid() = profile_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can insert own secret photos" ON public.secret_photos FOR INSERT WITH CHECK (auth.uid() = profile_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can delete own secret photos" ON public.secret_photos FOR DELETE USING (auth.uid() = profile_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

INSERT INTO storage.buckets (id, name, public) VALUES ('secret-photos', 'secret-photos', false) ON CONFLICT DO NOTHING;

DO $$ BEGIN
  CREATE POLICY "Users can upload own secret photos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'secret-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can delete own secret photos" ON storage.objects FOR DELETE USING (bucket_id = 'secret-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users can view own secret photos" ON storage.objects FOR SELECT USING (bucket_id = 'secret-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
