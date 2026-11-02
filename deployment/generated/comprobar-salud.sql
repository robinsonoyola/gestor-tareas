-- ASE Work - diagnóstico operativo de solo lectura.
-- Puede ejecutarse en el editor SQL cuando soporte necesite comprobar el servicio.
-- No muestra nombres, correos, títulos ni contenido de clientes.
SELECT 'configuracion' AS bloque,
 jsonb_build_object(
  'empresas_activas',(SELECT count(*) FROM public.organizations WHERE status='active'),
  'propietarios_activos',(SELECT count(*) FROM public.organization_memberships WHERE role='owner' AND status='active'),
  'almacenamiento_privado',EXISTS(SELECT 1 FROM storage.buckets WHERE id='task-files' AND public IS FALSE),
  'ejecutor_bloqueado',NOT has_schema_privilege('ase_tenant_executor','public','CREATE') AND NOT has_schema_privilege('ase_tenant_executor','ase_private','CREATE')
 ) AS estado
UNION ALL
SELECT 'automatizaciones',
 jsonb_build_object(
  'esperadas',2,
  'activas',(SELECT count(*) FROM cron.job WHERE active AND jobname IN ('ase-work-recurrences','ase-work-deadline-notifications')),
  'ultima_ejecucion',(SELECT max(end_time) FROM cron.job_run_details WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname IN ('ase-work-recurrences','ase-work-deadline-notifications'))),
  'fallos_24h',(SELECT count(*) FROM cron.job_run_details WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname IN ('ase-work-recurrences','ase-work-deadline-notifications')) AND status<>'succeeded' AND start_time>=now()-interval '24 hours')
 )
UNION ALL
SELECT 'operacion',
 jsonb_build_object(
  'fichajes_abiertos',(SELECT count(*) FROM public.checkins WHERE checkout_time IS NULL),
  'fichajes_abiertos_mas_24h',(SELECT count(*) FROM public.checkins WHERE checkout_time IS NULL AND checkin_time<now()-interval '24 hours'),
  'recurrencias_con_error',(SELECT count(*) FROM public.work_recurrences WHERE last_error IS NOT NULL),
  'empresas_sin_propietario',(SELECT count(*) FROM public.organizations o WHERE o.status='active' AND NOT EXISTS(SELECT 1 FROM public.organization_memberships m WHERE m.organization_id=o.id AND m.role='owner' AND m.status='active'))
 );

SELECT jobname,schedule,active
FROM cron.job
WHERE jobname IN ('ase-work-recurrences','ase-work-deadline-notifications')
ORDER BY jobname;
