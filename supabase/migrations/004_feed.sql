-- =============================================================================
-- Migration 004 — Feed: posts, media, reactions, comments, bookmarks
-- =============================================================================

CREATE TABLE public.posts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id       UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  content         TEXT NOT NULL DEFAULT '',
  is_published    BOOLEAN NOT NULL DEFAULT TRUE,
  likes_count     INTEGER NOT NULL DEFAULT 0 CHECK (likes_count >= 0),
  dislikes_count  INTEGER NOT NULL DEFAULT 0 CHECK (dislikes_count >= 0),
  comments_count  INTEGER NOT NULL DEFAULT 0 CHECK (comments_count >= 0),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT posts_content_len CHECK (char_length(content) <= 5000)
);

CREATE INDEX idx_posts_author ON public.posts (author_id, created_at DESC);
CREATE INDEX idx_posts_feed ON public.posts (created_at DESC) WHERE is_published = TRUE;

-- -----------------------------------------------------------------------------
CREATE TABLE public.post_media (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id         UUID NOT NULL REFERENCES public.posts (id) ON DELETE CASCADE,
  storage_path    TEXT NOT NULL,           -- bucket: post-media
  public_url      TEXT,
  media_type      TEXT NOT NULL DEFAULT 'image' CHECK (media_type IN ('image', 'video')),
  sort_order      SMALLINT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_post_media_post ON public.post_media (post_id, sort_order);

-- -----------------------------------------------------------------------------
-- หนึ่ง user ต่อหนึ่ง reaction ต่อหนึ่ง post (like หรือ dislike)
-- -----------------------------------------------------------------------------
CREATE TABLE public.post_reactions (
  post_id         UUID NOT NULL REFERENCES public.posts (id) ON DELETE CASCADE,
  profile_id      UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  reaction        public.post_reaction_type NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (post_id, profile_id)
);

CREATE INDEX idx_post_reactions_profile ON public.post_reactions (profile_id);

-- -----------------------------------------------------------------------------
CREATE TABLE public.post_comments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id         UUID NOT NULL REFERENCES public.posts (id) ON DELETE CASCADE,
  author_id       UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  content         TEXT NOT NULL,
  parent_id       UUID REFERENCES public.post_comments (id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT post_comments_content_len CHECK (char_length(content) BETWEEN 1 AND 2000)
);

CREATE INDEX idx_post_comments_post ON public.post_comments (post_id, created_at ASC);
CREATE INDEX idx_post_comments_author ON public.post_comments (author_id);

-- -----------------------------------------------------------------------------
CREATE TABLE public.post_bookmarks (
  post_id         UUID NOT NULL REFERENCES public.posts (id) ON DELETE CASCADE,
  profile_id      UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (post_id, profile_id)
);

CREATE INDEX idx_post_bookmarks_profile ON public.post_bookmarks (profile_id, created_at DESC);
