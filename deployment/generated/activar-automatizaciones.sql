-- ASE Work - automatizaciones internas independientes del navegador.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT cron.unschedule(jobid) FROM cron.job WHERE jobname IN ('ase-work-recurrences','ase-work-deadline-notifications');
SELECT cron.schedule('ase-work-recurrences','17 * * * *','SELECT ase_private.schedule_recurrences()');
SELECT cron.schedule('ase-work-deadline-notifications','27 * * * *','SELECT ase_private.schedule_deadline_notifications()');
COMMIT;
SELECT jobname,schedule,active FROM cron.job WHERE jobname IN ('ase-work-recurrences','ase-work-deadline-notifications') ORDER BY jobname;
