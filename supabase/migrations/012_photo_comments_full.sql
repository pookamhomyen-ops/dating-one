-- =============================================================================
-- Migration 012 — Profile Photo Comments (Complete with RLS & Test Data)
-- =============================================================================

-- Drop existing table if exists
DROP TABLE IF EXISTS public.profile_photo_comments CASCADE;

-- Create the main comments table
CREATE TABLE public.profile_photo_comments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_id        UUID NOT NULL REFERENCES public.profile_photos (id) ON DELETE CASCADE,
  commenter_id    UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  content         TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT photo_comments_content_len CHECK (char_length(content) BETWEEN 1 AND 500)
);

-- Create indexes for query performance
CREATE INDEX idx_photo_comments_photo ON public.profile_photo_comments (photo_id, created_at DESC);
CREATE INDEX idx_photo_comments_commenter ON public.profile_photo_comments (commenter_id);
CREATE INDEX idx_photo_comments_created ON public.profile_photo_comments (created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.profile_photo_comments ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Anyone can view comments
CREATE POLICY "Anyone can view photo comments" 
ON public.profile_photo_comments 
FOR SELECT 
USING (TRUE);

-- RLS Policy: Users can create comments
CREATE POLICY "Users can create photo comments" 
ON public.profile_photo_comments 
FOR INSERT 
WITH CHECK (
  auth.uid() = commenter_id 
  AND EXISTS (SELECT 1 FROM public.profiles WHERE id = commenter_id)
  AND EXISTS (SELECT 1 FROM public.profile_photos WHERE id = photo_id)
);

-- RLS Policy: Users can update their own comments
CREATE POLICY "Users can update their own photo comments" 
ON public.profile_photo_comments 
FOR UPDATE 
USING (auth.uid() = commenter_id)
WITH CHECK (auth.uid() = commenter_id);

-- RLS Policy: Users can delete their own comments
CREATE POLICY "Users can delete their own photo comments" 
ON public.profile_photo_comments 
FOR DELETE 
USING (auth.uid() = commenter_id);

-- Grant permissions
GRANT SELECT ON public.profile_photo_comments TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.profile_photo_comments TO authenticated;
