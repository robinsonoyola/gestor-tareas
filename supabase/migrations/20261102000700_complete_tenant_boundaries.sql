-- ASE Work: every organization-owned relation has its own tenant boundary.
BEGIN;

DROP POLICY IF EXISTS work_task_templates_executor ON public.work_task_templates;
CREATE POLICY work_task_templates_executor ON public.work_task_templates TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

DROP POLICY IF EXISTS work_task_template_events_executor ON public.work_task_template_events;
CREATE POLICY work_task_template_events_executor ON public.work_task_template_events TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

DROP POLICY IF EXISTS work_task_subtasks_executor ON public.work_task_subtasks;
CREATE POLICY work_task_subtasks_executor ON public.work_task_subtasks TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

DROP POLICY IF EXISTS work_task_subtask_events_executor ON public.work_task_subtask_events;
CREATE POLICY work_task_subtask_events_executor ON public.work_task_subtask_events TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

DROP POLICY IF EXISTS work_task_dependencies_executor ON public.work_task_dependencies;
CREATE POLICY work_task_dependencies_executor ON public.work_task_dependencies TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

DROP POLICY IF EXISTS work_task_dependency_events_executor ON public.work_task_dependency_events;
CREATE POLICY work_task_dependency_events_executor ON public.work_task_dependency_events TO ase_tenant_executor
 USING(organization_id=ase_private.current_org()) WITH CHECK(organization_id=ase_private.current_org());

NOTIFY pgrst,'reload schema';
COMMIT;
