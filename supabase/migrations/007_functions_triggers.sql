-- =============================================================================
-- Migration 007 — Functions, triggers, views
-- =============================================================================

-- -----------------------------------------------------------------------------
-- updated_at auto-update
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_posts_updated_at
  BEFORE UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_post_comments_updated_at
  BEFORE UPDATE ON public.post_comments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_post_reactions_updated_at
  BEFORE UPDATE ON public.post_reactions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Sync geography point จาก lat/lng
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_profile_location()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location = extensions.ST_SetSRID(
      extensions.ST_MakePoint(NEW.longitude, NEW.latitude),
      4326
    )::extensions.geography;
  ELSE
    NEW.location = NULL;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profiles_sync_location
  BEFORE INSERT OR UPDATE OF latitude, longitude ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.sync_profile_location();

-- -----------------------------------------------------------------------------
-- สร้าง profile อัตโนมัติเมื่อสมัคร Supabase Auth
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', split_part(NEW.email, '@', 1), 'สมาชิกใหม่')
  );

  INSERT INTO public.discovery_preferences (profile_id)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- -----------------------------------------------------------------------------
-- นับ likes_received เมื่อมี profile_like ใหม่
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_profile_like_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_exists BOOLEAN;
BEGIN
  UPDATE public.profiles
  SET likes_received_count = likes_received_count + 1
  WHERE id = NEW.liked_id;

  -- ตรวจ mutual like → สร้าง match
  SELECT EXISTS (
    SELECT 1 FROM public.profile_likes
    WHERE liker_id = NEW.liked_id AND liked_id = NEW.liker_id
  ) INTO v_exists;

  IF v_exists THEN
    INSERT INTO public.matches (user_a_id, user_b_id)
    VALUES (
      LEAST(NEW.liker_id, NEW.liked_id),
      GREATEST(NEW.liker_id, NEW.liked_id)
    )
    ON CONFLICT (user_a_id, user_b_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profile_like_insert
  AFTER INSERT ON public.profile_likes
  FOR EACH ROW EXECUTE FUNCTION public.on_profile_like_insert();

CREATE OR REPLACE FUNCTION public.on_profile_like_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET likes_received_count = GREATEST(likes_received_count - 1, 0)
  WHERE id = OLD.liked_id;
  RETURN OLD;
END;
$$;

CREATE TRIGGER trg_profile_like_delete
  AFTER DELETE ON public.profile_likes
  FOR EACH ROW EXECUTE FUNCTION public.on_profile_like_delete();

-- -----------------------------------------------------------------------------
-- นับ profile view (ไม่ซ้ำใน index รายวันแล้ว)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_profile_view_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET profile_views_count = profile_views_count + 1
  WHERE id = NEW.viewed_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profile_view_insert
  AFTER INSERT ON public.profile_views
  FOR EACH ROW EXECUTE FUNCTION public.on_profile_view_insert();

-- -----------------------------------------------------------------------------
-- Post reaction counters
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_post_reaction_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.reaction = 'like' THEN
      UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSE
      UPDATE public.posts SET dislikes_count = dislikes_count + 1 WHERE id = NEW.post_id;
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.reaction = 'like' THEN
      UPDATE public.posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.post_id;
    ELSE
      UPDATE public.posts SET dislikes_count = GREATEST(dislikes_count - 1, 0) WHERE id = OLD.post_id;
    END IF;
    IF NEW.reaction = 'like' THEN
      UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSE
      UPDATE public.posts SET dislikes_count = dislikes_count + 1 WHERE id = NEW.post_id;
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.reaction = 'like' THEN
      UPDATE public.posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.post_id;
    ELSE
      UPDATE public.posts SET dislikes_count = GREATEST(dislikes_count - 1, 0) WHERE id = OLD.post_id;
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

CREATE TRIGGER trg_post_reaction_change
  AFTER INSERT OR UPDATE OR DELETE ON public.post_reactions
  FOR EACH ROW EXECUTE FUNCTION public.on_post_reaction_change();

-- -----------------------------------------------------------------------------
-- Post comment counter
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_post_comment_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_post_comment_insert
  AFTER INSERT ON public.post_comments
  FOR EACH ROW EXECUTE FUNCTION public.on_post_comment_insert();

CREATE OR REPLACE FUNCTION public.on_post_comment_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = OLD.post_id;
  RETURN OLD;
END;
$$;

CREATE TRIGGER trg_post_comment_delete
  AFTER DELETE ON public.post_comments
  FOR EACH ROW EXECUTE FUNCTION public.on_post_comment_delete();

-- -----------------------------------------------------------------------------
-- Chat: อัปเดต conversation เมื่อมีข้อความใหม่
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_message_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.conversations
  SET
    last_message_at = NEW.created_at,
    last_message_preview = LEFT(NEW.body, 120)
  WHERE id = NEW.conversation_id;

  -- เพิ่ม unread ให้ฝ่ายที่ไม่ได้ส่ง
  UPDATE public.conversation_members
  SET unread_count = unread_count + 1
  WHERE conversation_id = NEW.conversation_id
    AND profile_id <> NEW.sender_id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_message_insert
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.on_message_insert();

-- -----------------------------------------------------------------------------
-- Helper: อายุจาก birth_date
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.profile_age(p public.profiles)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
  SELECT CASE
    WHEN p.birth_date IS NULL THEN NULL
    ELSE DATE_PART('year', AGE(CURRENT_DATE, p.birth_date))::INTEGER
  END;
$$;

-- -----------------------------------------------------------------------------
-- RPC: ผู้ใช้ใกล้คุณ (หน้าหาเพื่อน)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.discover_nearby_users(
  p_viewer_id UUID,
  p_max_km NUMERIC DEFAULT 50,
  p_gender_filter public.gender_type[] DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  profile_id UUID,
  display_name TEXT,
  gender public.gender_type,
  age INTEGER,
  province TEXT,
  district TEXT,
  university TEXT,
  occupation TEXT,
  bio TEXT,
  is_verified BOOLEAN,
  is_online BOOLEAN,
  last_seen_at TIMESTAMPTZ,
  distance_km NUMERIC,
  primary_photo_url TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH viewer AS (
    SELECT location FROM public.profiles WHERE id = p_viewer_id
  )
  SELECT
    p.id,
    p.display_name,
    p.gender,
    public.profile_age(p),
    p.province,
    p.district,
    p.university,
    p.occupation,
    p.bio,
    p.is_verified,
    p.is_online,
    p.last_seen_at,
    ROUND((extensions.ST_Distance(v.location, p.location) / 1000.0)::NUMERIC, 2) AS distance_km,
    ph.public_url
  FROM public.profiles p
  CROSS JOIN viewer v
  LEFT JOIN LATERAL (
    SELECT public_url FROM public.profile_photos
    WHERE profile_id = p.id
    ORDER BY is_primary DESC, sort_order ASC
    LIMIT 1
  ) ph ON TRUE
  WHERE p.id <> p_viewer_id
    AND p.id NOT IN (
      SELECT blocked_id FROM public.blocks WHERE blocker_id = p_viewer_id
      UNION
      SELECT blocker_id FROM public.blocks WHERE blocked_id = p_viewer_id
    )
    AND (p_gender_filter IS NULL OR p.gender = ANY (p_gender_filter))
    AND v.location IS NOT NULL
    AND p.location IS NOT NULL
    AND extensions.ST_DWithin(v.location, p.location, p_max_km * 1000)
  ORDER BY distance_km ASC
  LIMIT p_limit OFFSET p_offset;
$$;

-- -----------------------------------------------------------------------------
-- View: ฟีดโพสต์พร้อมข้อมูลผู้เขียน
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.feed_posts_v AS
SELECT
  po.id AS post_id,
  po.author_id,
  pr.display_name AS author_name,
  pr.gender AS author_gender,
  ph.public_url AS author_photo_url,
  po.content,
  po.likes_count,
  po.dislikes_count,
  po.comments_count,
  po.created_at,
  pm.public_url AS image_url
FROM public.posts po
JOIN public.profiles pr ON pr.id = po.author_id
LEFT JOIN LATERAL (
  SELECT public_url FROM public.profile_photos
  WHERE profile_id = po.author_id
  ORDER BY is_primary DESC, sort_order ASC
  LIMIT 1
) ph ON TRUE
LEFT JOIN LATERAL (
  SELECT public_url FROM public.post_media
  WHERE post_id = po.id
  ORDER BY sort_order ASC
  LIMIT 1
) pm ON TRUE
WHERE po.is_published = TRUE;

-- -----------------------------------------------------------------------------
-- View: รายการแชทของฉัน
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.my_conversations_v AS
SELECT
  c.id AS conversation_id,
  cm.profile_id AS my_id,
  CASE
    WHEN c.user_low_id = cm.profile_id THEN c.user_high_id
    ELSE c.user_low_id
  END AS partner_id,
  partner.display_name AS partner_name,
  pph.public_url AS partner_photo_url,
  c.last_message_preview,
  c.last_message_at,
  cm.unread_count,
  partner.is_online AS partner_is_online
FROM public.conversations c
JOIN public.conversation_members cm ON cm.conversation_id = c.id
JOIN public.profiles partner ON partner.id = CASE
  WHEN c.user_low_id = cm.profile_id THEN c.user_high_id
  ELSE c.user_low_id
END
LEFT JOIN LATERAL (
  SELECT public_url FROM public.profile_photos
  WHERE profile_id = partner.id
  ORDER BY is_primary DESC, sort_order ASC
  LIMIT 1
) pph ON TRUE;
