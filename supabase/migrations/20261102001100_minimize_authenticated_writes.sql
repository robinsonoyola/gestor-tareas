-- ASE Work: browser writes are limited to the operations still used directly by the UI.
BEGIN;

REVOKE INSERT,UPDATE,DELETE ON TABLE
 public.checkins,
 public.task_assignments,
 public.task_comments
FROM authenticated;

REVOKE INSERT,DELETE ON TABLE
 public.tasks,
 public.task_access_codes,
 public.task_checkin_config
FROM authenticated;

COMMIT;
