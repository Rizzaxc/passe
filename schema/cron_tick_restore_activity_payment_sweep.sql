-- Restore the existing post-activity tally when composing the shared
-- once-per-minute cron tick with Freeplay maintenance. The sweep itself
-- enforces the end_time + 15 minute eligibility window and is idempotent.

CREATE OR REPLACE FUNCTION public.fn_cron_tick()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $$
BEGIN
  PERFORM public.fn_sweep_challenges();
  PERFORM public.fn_sweep_activity_payment_requests();
  PERFORM public.fn_sweep_freeplay();
  PERFORM public.fn_process_reminders();
  IF EXISTS (
    SELECT 1
    FROM public.notification_outbox
    WHERE status IN ('pending', 'sending')
  ) THEN
    PERFORM public.fn_invoke_send_push();
  END IF;
END
$$;

REVOKE ALL ON FUNCTION public.fn_cron_tick()
FROM PUBLIC, anon, authenticated;
