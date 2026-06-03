-- =============================================================================
-- Migration 010 — Grants สำหรับ Supabase roles
-- =============================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;

-- Views
GRANT SELECT ON public.feed_posts_v TO authenticated;
GRANT SELECT ON public.my_conversations_v TO authenticated;

-- RPC
GRANT EXECUTE ON FUNCTION public.discover_nearby_users TO authenticated;
GRANT EXECUTE ON FUNCTION public.profile_age TO authenticated, anon;
