-- ============================================================================
-- friendly_challenge_sweep.sql — Part F of the friendly-challenge build.
-- Apply AFTER friendly_challenge.sql.
--
-- Everything in friendly mode that resolves by a clock rather than by a tap.
-- Rides the existing 1-minute fn_cron_tick — no new cron job.
--
-- Scoped strictly to mode = 'friendly'. fn_sweep_challenges keeps the refereed
-- rows; the two must never see the same challenge, for the same reason
-- fn_sweep_activity_thresholds excludes challenge activities entirely — two
-- sweeps racing on one deadline column is how a fixture gets voided twice.
--
-- Re-dump schema/passe.sql after applying (do not hand-edit the dump).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.fn_sweep_friendly_challenges()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    r record;
BEGIN
    -- ── (a) Offers that closed with nobody biting ───────────────────────────
    -- Nothing auto-renews. The managers get a push whose action re-posts the
    -- identical fixture a week on; miss it and the slot is simply free again.
    -- An auto_renew flag would let an abandoned lobby advertise a match it will
    -- never honour indefinitely, and the Discover feed would silently fill with
    -- fixtures nobody intends to play.
    FOR r IN
        SELECT o.id, o.lobby_id, o.slot, o.kickoff, l.name AS lobby_name
          FROM public.lobby_challenge_offer o
          JOIN public.lobby l ON l.id = o.lobby_id
         WHERE o.status = 'open' AND o.expires_at <= now()
         FOR UPDATE OF o
    LOOP
        UPDATE public.lobby_challenge_offer SET status = 'expired' WHERE id = r.id;
        PERFORM public.fn_lapse_offer_challenges(r.id, 'Lời mời thách đấu đã hết hạn');

        PERFORM public.fn_enqueue_notification(
            'challenge_offer_expired',
            ARRAY(SELECT uid FROM (
                SELECT captain_id AS uid FROM public.lobby WHERE id = r.lobby_id
                UNION
                SELECT user_id FROM public.lobby_member
                 WHERE lobby_id = r.lobby_id AND role = 'coordinator') s),
            'Lời mời hết hạn',
            'Chưa có đội nào nhận lời. Đăng lại cho tuần sau?',
            jsonb_build_object('lobby_id', r.lobby_id, 'offer_id', r.id));
    END LOOP;

    -- ── (b) No-show claims nobody answered ──────────────────────────────────
    -- The claimant's side wins by walkover. Cron granularity is one minute, so
    -- the real resolution lands at claimed_at + 10..11 minutes; the 10 is the
    -- promise made to the accused, not a guarantee to the claimant.
    FOR r IN
        SELECT c.id, c.no_show_claimed_by, c.target_lobby_id
          FROM public.lobby_challenge c
         WHERE c.mode = 'friendly'
           AND c.status = 'no_show_claimed'
           AND c.no_show_claimed_at + interval '10 minutes' <= now()
         FOR UPDATE OF c
    LOOP
        PERFORM public.fn_settle_friendly_challenge(
            r.id,
            -- Result is stated in the HOME frame: home claimed ⇒ home wins.
            CASE WHEN r.no_show_claimed_by = r.target_lobby_id
                 THEN 'win'::public.lobby_match_result
                 ELSE 'loss'::public.lobby_match_result END,
            'forfeit', NULL, NULL, 'Đối phương không có mặt');
    END LOOP;

    -- ── (c) Halfway reminder ────────────────────────────────────────────────
    -- Stamped so it fires once, not every minute for twelve hours. Goes only to
    -- the lobbies that have not filed — nagging a manager who already reported
    -- teaches them to ignore the channel.
    FOR r IN
        SELECT c.id, c.initiator_lobby_id, c.target_lobby_id
          FROM public.lobby_challenge c
          JOIN public.activity a ON a.challenge_id = c.id AND a.lobby_id = c.target_lobby_id
         WHERE c.mode = 'friendly'
           AND c.status = 'awaiting_reports'
           AND c.report_reminded_at IS NULL
           AND a.end_time + interval '12 hours' <= now()
         FOR UPDATE OF c
    LOOP
        UPDATE public.lobby_challenge SET report_reminded_at = now() WHERE id = r.id;

        -- One call per lobby, each carrying its OWN lobby_id — a shared one
        -- would route the away side's tap into the home lobby.
        IF NOT EXISTS (SELECT 1 FROM public.lobby_challenge_report
                        WHERE challenge_id = r.id AND lobby_id = r.target_lobby_id) THEN
            PERFORM public.fn_enqueue_notification(
                'match_result_pending',
                ARRAY(SELECT uid FROM (
                    SELECT captain_id AS uid FROM public.lobby WHERE id = r.target_lobby_id
                    UNION
                    SELECT user_id FROM public.lobby_member
                     WHERE lobby_id = r.target_lobby_id AND role = 'coordinator') s),
                'Chưa khai kết quả',
                'Còn 12 tiếng. Nếu chỉ một đội khai, kết quả của đội đó được ghi nhận.',
                jsonb_build_object('lobby_id', r.target_lobby_id, 'challenge_id', r.id));
        END IF;
        IF NOT EXISTS (SELECT 1 FROM public.lobby_challenge_report
                        WHERE challenge_id = r.id AND lobby_id = r.initiator_lobby_id) THEN
            PERFORM public.fn_enqueue_notification(
                'match_result_pending',
                ARRAY(SELECT uid FROM (
                    SELECT captain_id AS uid FROM public.lobby WHERE id = r.initiator_lobby_id
                    UNION
                    SELECT user_id FROM public.lobby_member
                     WHERE lobby_id = r.initiator_lobby_id AND role = 'coordinator') s),
                'Chưa khai kết quả',
                'Còn 12 tiếng. Nếu chỉ một đội khai, kết quả của đội đó được ghi nhận.',
                jsonb_build_object('lobby_id', r.initiator_lobby_id, 'challenge_id', r.id));
        END IF;
    END LOOP;

    -- ── (d) The 24h window closes ───────────────────────────────────────────
    -- One report on file ⇒ it stands and rates. This is the deliberate residual
    -- in the design: a dishonest reporter profits against an opponent who
    -- ignores both pushes for a full day. The alternative — silence means
    -- unrated — protects that case perfectly but leaves most matches unrated,
    -- and a ladder that rarely moves is not a ladder. The dispute penalty and
    -- the trust ramp are what price the residual instead.
    --
    -- No reports at all ⇒ a scoreless practice encounter: present in both
    -- histories so the two lobbies can still settle between themselves, but
    -- moving no rating, because nobody said what happened.
    FOR r IN
        SELECT c.id,
               (SELECT count(*) FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id) AS n,
               (SELECT rr.result FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id LIMIT 1) AS only_result,
               (SELECT rr.is_forfeit FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id LIMIT 1) AS only_forfeit,
               (SELECT rr.sets FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id LIMIT 1) AS only_sets,
               (SELECT rr.mvp_user_id FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id LIMIT 1) AS only_mvp,
               (SELECT rr.note FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id LIMIT 1) AS only_note
          FROM public.lobby_challenge c
          JOIN public.activity a ON a.challenge_id = c.id AND a.lobby_id = c.target_lobby_id
         WHERE c.mode = 'friendly'
           AND c.status IN ('awaiting_reports', 'scheduled')
           AND a.end_time + interval '24 hours' <= now()
         FOR UPDATE OF c
    LOOP
        IF r.n = 1 THEN
            PERFORM public.fn_settle_friendly_challenge(
                r.id, r.only_result,
                CASE WHEN r.only_forfeit THEN 'forfeit'::public.match_result_source
                     ELSE 'one_sided'::public.match_result_source END,
                r.only_sets, r.only_mvp, r.only_note);
        ELSE
            PERFORM public.fn_settle_friendly_challenge(
                r.id, 'practice', 'one_sided', NULL, NULL,
                'Không đội nào khai kết quả');
        END IF;
    END LOOP;
END;
$$;
REVOKE ALL ON FUNCTION public.fn_sweep_friendly_challenges() FROM PUBLIC, anon, authenticated;

-- ─── Wire into the existing 1-minute tick ───────────────────────────────────
-- Extends the authoritative definition (activity_threshold_enforcement.sql),
-- not the superseded one in challenge_flow.sql.
CREATE OR REPLACE FUNCTION public.fn_cron_tick()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  PERFORM public.fn_sweep_challenges();
  PERFORM public.fn_sweep_friendly_challenges();
  PERFORM public.fn_sweep_activity_thresholds();
  PERFORM public.fn_sweep_activity_payment_requests();
  PERFORM public.fn_sweep_freeplay();
  PERFORM public.fn_sweep_course_targets();
  PERFORM public.fn_process_reminders();
  IF EXISTS (SELECT 1 FROM public.notification_outbox WHERE status IN ('pending','sending')) THEN
    PERFORM public.fn_invoke_send_push();
  END IF;
END;
$$;


-- ─── Keep the refereed sweep off friendly rows ──────────────────────────────
-- fn_sweep_challenges' "played but never scored" pass fires on status
-- 'scheduled', which friendly challenges also reach — it would settle a
-- friendly match as a scoreless practice encounter while pass (d) above was
-- trying to settle it from the blind reports. Two sweeps on one row is exactly
-- the race fn_sweep_activity_thresholds already avoids by excluding challenge
-- activities outright, so both are scoped by mode instead.
--
-- Its offer-expiry pass is also removed: offers live in lobby_challenge_offer
-- now and are expired for BOTH modes by pass (a) above.
CREATE OR REPLACE FUNCTION public.fn_sweep_challenges()
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    r record;
BEGIN
    -- (a) Offer expiry moved to lobby_challenge_offer, swept for BOTH modes
    -- by fn_sweep_friendly_challenges pass (a). The lobby.challenge_offer_*
    -- columns this pass read no longer exist.

    -- (b) A challenge whose confirmation deadline passed with a side short of
    --     quorum (or a manager who never confirmed): void both activities.
    FOR r IN
        SELECT c.id, c.initiator_lobby_id, c.target_lobby_id
          FROM public.lobby_challenge c
         WHERE c.mode = 'refereed'
           AND c.status = 'accepted'
           AND EXISTS (
               SELECT 1 FROM public.activity a
                WHERE a.challenge_id = c.id
                  AND a.confirmation_deadline IS NOT NULL
                  AND a.confirmation_deadline <= now()
                  AND a.manager_confirmed_at IS NULL)
    LOOP
        DELETE FROM public.activity WHERE challenge_id = r.id;
        UPDATE public.lobby_challenge
           SET status = 'lapsed', updated_at = now() WHERE id = r.id;

        -- One call per lobby, each carrying its OWN lobby_id — a single
        -- shared lobby_id (as this originally shipped) routed every
        -- initiator-side member's tap straight to the TARGET lobby.
        PERFORM public.fn_enqueue_notification(
            'challenge_lapsed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.initiator_lobby_id),
            'Trận thách đấu bị huỷ',
            'Không đủ xác nhận trước hạn chót nên trận đấu đã bị huỷ',
            jsonb_build_object('lobby_id', r.initiator_lobby_id, 'challenge_id', r.id));
        PERFORM public.fn_enqueue_notification(
            'challenge_lapsed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.target_lobby_id),
            'Trận thách đấu bị huỷ',
            'Không đủ xác nhận trước hạn chót nên trận đấu đã bị huỷ',
            jsonb_build_object('lobby_id', r.target_lobby_id, 'challenge_id', r.id));

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        SELECT l.id, l.captain_id, 'update',
               jsonb_build_object(
                   'title', 'Trận thách đấu bị huỷ',
                   'kind',  'cancelled',
                   'tone',  'crimson',
                   'fields', jsonb_build_array(
                       jsonb_build_array('Lý do', 'Không đủ xác nhận trước hạn chót')))
          FROM public.lobby l
         WHERE l.id IN (r.initiator_lobby_id, r.target_lobby_id);
    END LOOP;

    -- (c) A match that was played but never scored — no referee was booked, or
    --     one was and never recorded. It still happened, so it is logged for
    --     BOTH sides as an encounter with no score, and moves no rating. Doing
    --     this on a timer rather than as a captain action is what keeps one
    --     side from stamping a result into the other's record.
    FOR r IN
        SELECT c.id, c.target_lobby_id AS home, c.initiator_lobby_id AS away,
               a.id AS activity_id, a.start_time, a.location_id
          FROM public.lobby_challenge c
          JOIN public.activity a
            ON a.challenge_id = c.id AND a.lobby_id = c.target_lobby_id
         WHERE c.mode = 'refereed'
           AND c.status IN ('accepted', 'scheduled')
           AND COALESCE(a.end_time, a.start_time) <= now()
           AND NOT EXISTS (SELECT 1 FROM public.lobby_match m WHERE m.activity_id = a.id)
    LOOP
        INSERT INTO public.lobby_match
            (lobby_id, activity_id, opponent_lobby_id, opponent_tag, result,
             venue_label, played_at)
        VALUES (r.home, r.activity_id, r.away,
                COALESCE((SELECT name FROM public.lobby WHERE id = r.away), '—'),
                'practice',
                COALESCE((SELECT name FROM public.location WHERE id = r.location_id), '—'),
                r.start_time);

        UPDATE public.lobby_challenge
           SET status = 'played', updated_at = now() WHERE id = r.id;

        -- Neither lobby was told anything when this shipped — a match that
        -- passed unrefereed just silently turned into a scoreless row. One
        -- call per lobby, its own lobby_id.
        PERFORM public.fn_enqueue_notification(
            'match_result_recorded',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.home),
            'Trận đấu đã diễn ra',
            'Không có trọng tài nên trận đấu được ghi nhận nhưng không tính điểm',
            jsonb_build_object('lobby_id', r.home, 'challenge_id', r.id));
        PERFORM public.fn_enqueue_notification(
            'match_result_recorded',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.away),
            'Trận đấu đã diễn ra',
            'Không có trọng tài nên trận đấu được ghi nhận nhưng không tính điểm',
            jsonb_build_object('lobby_id', r.away, 'challenge_id', r.id));
    END LOOP;
END;
$$;
