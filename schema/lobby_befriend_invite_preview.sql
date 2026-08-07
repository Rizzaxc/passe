-- ─────────────────────────────────────────────────────────────────
-- Public preview for a `lobby_befriend_record` (interaction_type = 'invite')
-- row, keyed by the record id sent in the `lobby_invite` push payload
-- (see fn_notify_lobby_invite in schema/lobby_befriend_invite_notify.sql).
-- Backs the LobbyInvitePreviewPage reached from a `lobby_invite`
-- notification tap. Unlike get_lobby_invite_preview (the Discord-style
-- invite-link flow), this always requires auth — the row only exists for a
-- specific signed-in target user, there's no anon/guest case to support.
--
-- Response is tiered by the target lobby's own `lobby_visibility`, each tier
-- additive on top of the last:
--   (always)      lobby_id, lobby_name, has_avatar
--   discoverable+ member_count, captain_username, relationship (this
--                 viewer's FriendState vs the captain, same values as
--                 user_profile_data's friend_state), fitscore
--                 (calculate_profile_compat_score, the same "FitScore" the
--                 Home teammate/challenger feeds show)
--   public        home_ground_name, playtime, mmr, is_mmr_calibrated,
--                 members (full roster: username + tag_number)
-- `status`/`inviter_username` are about the invite itself, not the lobby's
-- own visibility, so they're always included regardless of tier.
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_lobby_befriend_invite_preview(
    p_record_id uuid
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_rec record;
    v_result jsonb;
    v_friend_status public.lobby_befriend_status;
    v_addressee uuid;
    v_relationship text;
BEGIN
    IF v_uid IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'not_found');
    END IF;

    SELECT bfr.status, bfr.target_lobby_id,
           l.name AS lobby_name, l.details AS lobby_details, l.visibility,
           l.sport_id, l.captain_id, l.home_ground, l.playtime, l.mmr,
           cap.username AS captain_username,
           ini.username AS inviter_username
      INTO v_rec
      FROM public.lobby_befriend_record bfr
      JOIN public.lobby l ON l.id = bfr.target_lobby_id
      JOIN public."user" cap ON cap.id = l.captain_id
      JOIN public."user" ini ON ini.id = bfr.initiator_user_id
     WHERE bfr.id = p_record_id
       AND bfr.target_user_id = v_uid
       AND bfr.interaction_type = 'invite';

    IF v_rec IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'not_found');
    END IF;

    -- Base tier: shown regardless of the lobby's visibility.
    v_result := jsonb_build_object(
        'valid', true,
        'status', v_rec.status,
        'lobby_id', v_rec.target_lobby_id,
        'lobby_name', v_rec.lobby_name,
        'has_avatar', coalesce((v_rec.lobby_details ->> 'hasAvatar')::boolean, false),
        'visibility', v_rec.visibility,
        'inviter_username', v_rec.inviter_username
    );

    IF v_rec.visibility IN ('discoverable', 'public') THEN
        SELECT f.status, f.addressee_id INTO v_friend_status, v_addressee
          FROM public.friendship f
         WHERE f.status IN ('pending', 'accepted')
           AND least(f.requester_id, f.addressee_id) = least(v_uid, v_rec.captain_id)
           AND greatest(f.requester_id, f.addressee_id) = greatest(v_uid, v_rec.captain_id);

        v_relationship := CASE
            WHEN public.fn_is_blocked(v_uid, v_rec.captain_id) THEN 'blocked'
            WHEN v_friend_status = 'accepted' THEN 'friend'
            WHEN v_friend_status = 'pending' AND v_addressee = v_uid THEN 'incoming'
            WHEN v_friend_status = 'pending' THEN 'outgoing'
            ELSE 'none'
        END;

        v_result := v_result || jsonb_build_object(
            'member_count', (
                SELECT count(*) FROM public.lobby_member lm
                 WHERE lm.lobby_id = v_rec.target_lobby_id
            ),
            'captain_username', v_rec.captain_username,
            'relationship', v_relationship,
            'fitscore', public.calculate_profile_compat_score(
                v_uid, v_rec.target_lobby_id, v_rec.sport_id
            )
        );
    END IF;

    IF v_rec.visibility = 'public' THEN
        v_result := v_result || jsonb_build_object(
            'home_ground_name', (
                SELECT loc.name FROM public.location loc
                 WHERE loc.id = v_rec.home_ground
            ),
            'playtime', v_rec.playtime,
            'mmr', v_rec.mmr,
            'is_mmr_calibrated', EXISTS(
                SELECT 1 FROM public.lobby_match lm
                 WHERE lm.lobby_id = v_rec.target_lobby_id
                   AND lm.opponent_lobby_id IS NOT NULL
            ),
            'members', (
                SELECT coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'username', u.username, 'tag_number', u.tag_number
                        ) ORDER BY u.username
                    ),
                    '[]'::jsonb
                )
                  FROM public.lobby_member lm2
                  JOIN public."user" u ON u.id = lm2.user_id
                 WHERE lm2.lobby_id = v_rec.target_lobby_id
            )
        );
    END IF;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_lobby_befriend_invite_preview(uuid) TO authenticated;
