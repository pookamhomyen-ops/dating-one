CREATE OR REPLACE VIEW discover_profiles_v AS
WITH primary_photos AS (
  SELECT DISTINCT ON (profile_id)
    profile_id,
    public_url
  FROM profile_photos
  ORDER BY profile_id, is_primary DESC, sort_order ASC
),
profile_interests_list AS (
  SELECT 
    pi.profile_id,
    array_agg(i.name) AS interests
  FROM profile_interests pi
  JOIN interests i ON pi.interest_id = i.id
  GROUP BY pi.profile_id
)
SELECT 
  p.id,
  p.display_name,
  p.gender,
  p.birth_date,
  p.bio,
  p.province,
  p.district,
  p.university,
  p.occupation,
  p.is_verified,
  p.is_online,
  p.latitude,
  p.longitude,
  pp.public_url AS photo_url,
  COALESCE(pil.interests, ARRAY[]::text[]) AS interests
FROM profiles p
LEFT JOIN primary_photos pp ON p.id = pp.profile_id
LEFT JOIN profile_interests_list pil ON p.id = pil.profile_id;
