-- =============================================================================
-- Migration 012 — Profile Photo Comments
-- =============================================================================

CREATE TABLE public.profile_photo_comments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_id        UUID NOT NULL REFERENCES public.profile_photos (id) ON DELETE CASCADE,
  commenter_id    UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  content         TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT photo_comments_content_len CHECK (char_length(content) BETWEEN 1 AND 500)
);

CREATE INDEX idx_photo_comments_photo ON public.profile_photo_comments (photo_id, created_at DESC);
CREATE INDEX idx_photo_comments_commenter ON public.profile_photo_comments (commenter_id);
