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
 IF has_schema_privilege('public','ase_private','USAGE') THEN failures:=array_append(failures,'El esquema privado permite acceso público'); END IF;
 IF EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='ase_private' AND c.relkind IN ('r','p','v','m') AND (has_table_privilege('anon',c.oid,'SELECT,INSERT,UPDATE,DELETE') OR has_table_privilege('authenticated',c.oid,'SELECT,INSERT,UPDATE,DELETE'))) THEN failures:=array_append(failures,'Hay relaciones privadas expuestas al API'); END IF;
 IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='ase_private' AND has_function_privilege('public',p.oid,'EXECUTE')) THEN failures:=array_append(failures,'Hay funciones privadas expuestas a PUBLIC'); END IF;
 IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND has_function_privilege('anon',p.oid,'EXECUTE'))<>11 OR EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND has_function_privilege('anon',p.oid,'EXECUTE') AND NOT p.oid=ANY(ARRAY['public.work_station_checklist(text,uuid,uuid,boolean)'::regprocedure,'public.work_station_confirm(text,uuid,text)'::regprocedure,'public.work_station_confirm_v2(text,uuid,text)'::regprocedure,'public.work_station_day(text,uuid)'::regprocedure,'public.work_station_day_v2(text,uuid)'::regprocedure,'public.work_station_identify(text,text)'::regprocedure,'public.work_station_identify_result(text,text,text,uuid)'::regprocedure,'public.work_station_identify_v2(text,text,text,uuid)'::regprocedure,'public.work_station_people(text)'::regprocedure,'public.work_station_save_result(text,uuid,text)'::regprocedure,'public.work_usability_ready()'::regprocedure])) THEN failures:=array_append(failures,'La superficie anónima del API no coincide con los puntos de fichaje'); END IF;
 IF (SELECT count(*) FROM cron.job WHERE active AND jobname IN ('ase-work-recurrences','ase-work-deadline-notifications'))<>2 THEN failures:=array_append(failures,'Automatizaciones horarias incompletas'); END IF;
 IF cardinality(failures)>0 THEN RAISE EXCEPTION 'Instalación incompleta: %',array_to_string(failures,'; '); END IF;
END $verify$;
SELECT 'ASE Work listo' AS resultado,
 (SELECT count(*) FROM public.organizations WHERE status='active') AS empresas_activas,
 (SELECT count(*) FROM cron.job WHERE active AND jobname IN ('ase-work-recurrences','ase-work-deadline-notifications')) AS automatizaciones_activas;
