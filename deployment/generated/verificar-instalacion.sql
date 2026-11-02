-- ASE Work - verificación posterior a instalación. No modifica datos.
DO $verify$
DECLARE failures text[]:='{}';
BEGIN
 IF to_regclass('public.organizations') IS NULL OR to_regclass('public.work_task_archive_events') IS NULL OR to_regclass('public.work_projects') IS NULL THEN failures:=array_append(failures,'Faltan tablas del gestor'); END IF;
 IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tasks' AND column_name='archived_at') THEN failures:=array_append(failures,'Falta archivo de actividades'); END IF;
 IF NOT EXISTS(SELECT 1 FROM public.organization_memberships WHERE role='owner' AND status='active') THEN failures:=array_append(failures,'Falta propietario activo'); END IF;
 IF NOT EXISTS(SELECT 1 FROM storage.buckets WHERE id='task-files' AND public IS FALSE) THEN failures:=array_append(failures,'El almacenamiento task-files no es privado'); END IF;
 IF has_schema_privilege('ase_tenant_executor','public','CREATE') OR has_schema_privilege('ase_tenant_executor','ase_private','CREATE') THEN failures:=array_append(failures,'El ejecutor conserva CREATE'); END IF;
 IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname IN ('anon','authenticated') AND (rolsuper OR rolbypassrls)) THEN failures:=array_append(failures,'Rol API con privilegios elevados'); END IF;
 IF (SELECT count(*) FROM cron.job WHERE active AND jobname IN ('ase-work-recurrences','ase-work-deadline-notifications'))<>2 THEN failures:=array_append(failures,'Automatizaciones horarias incompletas'); END IF;
 IF cardinality(failures)>0 THEN RAISE EXCEPTION 'Instalación incompleta: %',array_to_string(failures,'; '); END IF;
END $verify$;
SELECT 'ASE Work listo' AS resultado,
 (SELECT count(*) FROM public.organizations WHERE status='active') AS empresas_activas,
 (SELECT count(*) FROM cron.job WHERE active AND jobname IN ('ase-work-recurrences','ase-work-deadline-notifications')) AS automatizaciones_activas;
