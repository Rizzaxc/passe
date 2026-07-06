-- Split soccer_profile.position value 'outfield' into 'forward', 'midfielder', 'defender'.
--
-- 'outfield' was a single catch-all for any non-goalkeeper position. There's no way to recover
-- which specific position a player meant, so existing 'outfield' entries are expanded to all
-- three new values (keeps them visible under any of the more specific filters instead of losing
-- the data); users can re-narrow it next time they edit their profile. 'keeper' is untouched.

UPDATE soccer_profile
SET "position" = (
    SELECT array_agg(DISTINCT v)
    FROM unnest(
        array_cat(
            array_remove("position", 'outfield'),
            CASE WHEN 'outfield' = ANY("position")
                THEN ARRAY['forward', 'midfielder', 'defender']
                ELSE ARRAY[]::text[]
            END
        )
    ) AS v
)
WHERE 'outfield' = ANY("position");
