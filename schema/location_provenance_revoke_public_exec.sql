-- Follow-up to location_provenance.sql: CREATE FUNCTION (and DROP+CREATE,
-- used there to change these three functions' signatures) implicitly
-- (re-)grants EXECUTE to PUBLIC, which includes the `anon` role. The
-- original dump explicitly revoked that for `request_referee_booking` and
-- `create_freeplay_activity` before re-granting only to
-- authenticated/service_role; recreating them with new signatures dropped
-- that revoke. `create_location` is equally auth-gated (it raises on a null
-- auth.uid()) and was missing it from the start. Restore the
-- revoke-then-grant-explicitly posture for all three, caught by
-- get_advisors' `0028_anon_security_definer_function_executable` lint.

REVOKE ALL ON FUNCTION public.create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint) TO authenticated;
GRANT ALL ON FUNCTION public.create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint) TO service_role;

REVOKE ALL ON FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) TO service_role;

REVOKE ALL ON FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid) TO service_role;
