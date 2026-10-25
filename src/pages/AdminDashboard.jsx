import {ImportanceBadge,ImportanceField,TaskTimeline} from '@/components/TaskImportance'
import ChecklistEditor from '@/components/checklists/ChecklistEditor'
import {MobileTasks} from './admin/MobileRecords'
import { useState, useEffect } from 'react'
import TaskFollowup from './admin/TaskFollowup'
import ReviewQueue from './admin/ReviewQueue'
import { useSearchParams } from 'react-router-dom'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { workDate, workRpc } from '@/lib/workflow'
import Layout from '@/components/layout/Layout'
import { Button } from '@/components/ui/button'
import { sectionTabClass, sectionTabsClass } from '@/components/ui/section-tabs'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Checkbox } from '@/components/ui/checkbox'
import { 
  Plus, 
  Edit, 
  Copy,
  Trash2, 
  Calendar,
  Users,
  CheckSquare,
  QrCode,
  MapPin
} from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { useAuth } from '@/hooks/useAuth'

export default function AdminDashboard() {
  const navigate = useNavigate()
  const [query,setQuery]=useSearchParams()
  const [search,setSearch]=useState('')
  const [employeeFilter,setEmployeeFilter]=useState('')
  const [statusFilter,setStatusFilter]=useState('all')
  const [importanceFilter,setImportanceFilter]=useState('all')
  const { can, isAdmin } = useAuth()
  const [tasks, setTasks] = useState([])
  const [employees, setEmployees] = useState([])
  const [areas, setAreas] = useState([])
  const [assignmentLoad,setAssignmentLoad] = useState({})
  const [loading, setLoading] = useState(true)
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
  const [isEditModalOpen, setIsEditModalOpen] = useState(false)
  const [checklistTask,setChecklistTask]=useState(null)
  const [selectedTask, setSelectedTask] = useState(null)
  
  const [taskForm, setTaskForm] = useState({
    title: '',
    description: '',
    labels_text: '',
    location: '',
    source_module: '',
    related_entity_type: '',
    related_entity_reference: '',
    related_entity_label: '',
    require_result: false,
    schedule_type: 'daily',
    importance: 'normal',
    schedule_date: '',
    status: 'pending',
    primary_user: '',
    collaborators: [],
    followers: [],
    area_id: '',
    require_comment: false,
    require_photo: false,
    require_video: false,
    require_file: false,
    estimated_minutes: '',
    requires_review: false
  })

  useEffect(() => {
    fetchTasks()
    fetchEmployees()
    fetchAreas()
    fetchAssignmentLoad()
  }, [])

  const fetchTasks = async () => {
    try {
      setLoading(true)
      const data = await workRpc('work_task_catalog_labeled')
      const tasksWithUsers = data.map(task=>{const primary=task.assigned_users.find(u=>u.role==='primary'),collaborators=task.assigned_users.filter(u=>u.role!=='primary');return {...task,assigned_names:[task.area&&`Área: ${task.area.name}`,primary&&`Responsable: ${primary.full_name}`,collaborators.length&&`Colaboran: ${collaborators.map(u=>u.full_name).join(', ')}`,task.followers?.length&&`Siguen: ${task.followers.map(u=>u.full_name).join(', ')}`,task.area&&!task.assigned_users.length&&'Pendiente de asignar'].filter(Boolean).join(' · ')||'Sin asignar'}})
      setTasks(tasksWithUsers)
    } catch (error) {
      console.error('Error fetching tasks:', error)
      toast.error('Error al cargar las tareas')
    } finally {
      setLoading(false)
    }
  }

  const fetchEmployees = async () => {
    try {
      const data = await workRpc('work_employee_directory')
      setEmployees(data || [])
    } catch (error) {
      console.error('Error fetching employees:', error)
    }
  }

  const fetchAreas = async () => {
    try {
      const data = await workRpc('work_area_directory')
      setAreas(data?.areas || [])
    } catch (error) {
      console.error('Error fetching areas:', error)
    }
  }

  const fetchAssignmentLoad = async () => {
    try { const data=await workRpc('work_assignment_workload',{p_start:null,p_end:null});setAssignmentLoad(Object.fromEntries((data?.employees||[]).map(row=>[row.id,row]))) }
    catch { setAssignmentLoad({}) }
  }

  const handleCreateTask = async (e) => {
    e.preventDefault()

    try {
      await workRpc('work_manage_task_outcome',{p_importance:taskForm.importance||'normal',p_action:'create',p_title:taskForm.title,p_description:taskForm.description,p_schedule:taskForm.schedule_type,p_date:taskForm.schedule_date||null,p_status:taskForm.status,p_primary:taskForm.primary_user||null,p_collaborators:taskForm.collaborators,p_followers:taskForm.followers,p_require_comment:taskForm.require_comment,p_require_photo:taskForm.require_photo,p_require_video:taskForm.require_video,p_require_file:taskForm.require_file,p_estimated_minutes:taskForm.estimated_minutes?Number(taskForm.estimated_minutes):null,p_requires_review:taskForm.requires_review,p_area:taskForm.area_id||null,p_labels:taskForm.labels_text.split(',').map(label=>label.trim()).filter(Boolean),p_location:taskForm.location||null,p_source_module:taskForm.source_module||null,p_entity_type:taskForm.related_entity_type||null,p_entity_reference:taskForm.related_entity_reference||null,p_entity_label:taskForm.related_entity_label||null,p_require_result:taskForm.require_result})
      toast.success('✅ Tarea creada correctamente')
      setIsCreateModalOpen(false)
      resetForm()
      fetchTasks()
    } catch (error) {
      console.error('Error creating task:', error)
      const message=String(error?.message||error||'')
      toast.error(message.includes('work_manage_task_outcome')?'Falta activar el resultado obligatorio en Supabase.':message||'Error al crear la tarea')
    }
  }

  const handleEditTask = async (e) => {
    e.preventDefault()

    try {
      await workRpc('work_manage_task_outcome',{p_importance:taskForm.importance||'normal',p_action:'edit',p_id:selectedTask.id,p_title:taskForm.title,p_description:taskForm.description,p_schedule:taskForm.schedule_type,p_date:taskForm.schedule_date||null,p_status:taskForm.status,p_primary:taskForm.primary_user||null,p_collaborators:taskForm.collaborators,p_followers:taskForm.followers,p_require_comment:taskForm.require_comment,p_require_photo:taskForm.require_photo,p_require_video:taskForm.require_video,p_require_file:taskForm.require_file,p_estimated_minutes:taskForm.estimated_minutes?Number(taskForm.estimated_minutes):null,p_requires_review:taskForm.requires_review,p_area:taskForm.area_id||null,p_labels:taskForm.labels_text.split(',').map(label=>label.trim()).filter(Boolean),p_location:taskForm.location||null,p_source_module:taskForm.source_module||null,p_entity_type:taskForm.related_entity_type||null,p_entity_reference:taskForm.related_entity_reference||null,p_entity_label:taskForm.related_entity_label||null,p_require_result:taskForm.require_result})
      toast.success('✅ Tarea actualizada correctamente')
      setIsEditModalOpen(false)
      setSelectedTask(null)
      resetForm()
      fetchTasks()
    } catch (error) {
      console.error('Error updating task:', error)
      const message=String(error?.message||error||'')
      toast.error(message.includes('work_manage_task_outcome')?'Falta activar el resultado obligatorio en Supabase.':message||'Error al actualizar la tarea')
    }
  }

  const handleDeleteTask = async (taskId) => {
    if (!window.confirm('¿Estás seguro de eliminar esta tarea?')) return

    try {
      await workRpc('work_manage_task',{p_action:'delete',p_id:taskId})
      toast.success('✅ Tarea eliminada')
      fetchTasks()
    } catch (error) {
      console.error('Error deleting task:', error)
      toast.error('Error al eliminar la tarea')
    }
  }

  const handleDuplicateTask = async task => {
    try { await workRpc('work_duplicate_task',{p_task:task.id,p_title:`${task.title} (copia)`});toast.success('Actividad duplicada sin copiar ejecuciones ni historial');await fetchTasks() }
    catch(error){const message=String(error?.message||error||'');toast.error(message.includes('work_duplicate_task')?'Falta activar la duplicación de actividades en Supabase.':message||'No se pudo duplicar la actividad')}
  }

  const openEditModal = (task) => {
    fetchAssignmentLoad()
    setSelectedTask(task)
    setTaskForm({
      title: task.title,
      description: task.description || '',
      labels_text: (task.labels||[]).join(', '),
      location: task.location || '',
      source_module: task.source_module || '',
      related_entity_type: task.related_entity_type || '',
      related_entity_reference: task.related_entity_reference || '',
      related_entity_label: task.related_entity_label || '',
      require_result: Boolean(task.require_result),
      schedule_type: task.schedule_type,
      importance: task.importance || 'normal',
      schedule_date: task.schedule_date || '',
      status: task.status,
      primary_user: task.assigned_users.find(u=>u.role==='primary')?.id || '',
      collaborators: task.assigned_users.filter(u=>u.role!=='primary').map(u=>u.id),
      followers: (task.followers||[]).map(u=>u.id),
      area_id: task.area?.id || '',
      require_comment: Boolean(task.require_comment),
      require_photo: Boolean(task.require_photo),
      require_video: Boolean(task.require_video),
      require_file: Boolean(task.require_file)
      ,estimated_minutes: task.estimated_minutes || ''
      ,requires_review: Boolean(task.requires_review)
    })
    setIsEditModalOpen(true)
  }

  const resetForm = () => {
    setTaskForm({
      title: '',
      description: '',
      labels_text: '',
      location: '',
      source_module: '',
      related_entity_type: '',
      related_entity_reference: '',
      related_entity_label: '',
      require_result: false,
      schedule_type: 'daily',
      importance: 'normal',
      schedule_date: '',
      status: 'pending',
      primary_user: '',
      collaborators: [],
      followers: [],
      area_id: '',
      require_comment: false,
      require_photo: false,
      require_video: false,
      require_file: false
      ,estimated_minutes: ''
      ,requires_review: false
    })
  }

  const setPrimaryUser = userId => setTaskForm(prev=>({...prev,primary_user:userId,collaborators:prev.collaborators.filter(id=>id!==userId),followers:prev.followers.filter(id=>id!==userId)}))
  const togglePersonRole = (role,userId) => setTaskForm(prev=>{const selected=prev[role].includes(userId);return {...prev,[role]:selected?prev[role].filter(id=>id!==userId):[...prev[role],userId],primary_user:prev.primary_user===userId?'':prev.primary_user,[role==='collaborators'?'followers':'collaborators']:prev[role==='collaborators'?'followers':'collaborators'].filter(id=>id!==userId)}})
  const executorEmployees = taskForm.area_id ? employees.filter(e=>areas.find(a=>a.id===taskForm.area_id)?.members.includes(e.id)) : employees
  const setTaskArea = areaId => setTaskForm(prev=>{const members=areas.find(a=>a.id===areaId)?.members||[];return {...prev,area_id:areaId,primary_user:areaId&& !members.includes(prev.primary_user)?'':prev.primary_user,collaborators:areaId?prev.collaborators.filter(id=>members.includes(id)):prev.collaborators}})
  const workloadText = employee => {const load=assignmentLoad[employee.id];return load?`${employee.full_name} · ${load.open_count} abiertas${load.active_count?` · ${load.active_count} en curso`:''}${load.estimated_minutes?` · ${load.estimated_minutes} min previstos`:''}`:employee.full_name}
  const peopleFields = prefix => <div className="space-y-4"><div className="space-y-2"><Label htmlFor={`${prefix}-area`} className="text-gray-900 font-semibold">Área responsable</Label><select id={`${prefix}-area`} className="w-full border rounded-md bg-white p-2" value={taskForm.area_id} onChange={e=>setTaskArea(e.target.value)}><option value="">Sin área concreta</option>{areas.map(a=><option key={a.id} value={a.id}>{a.name}</option>)}</select><p className="text-xs text-gray-500">Puedes dejar la tarea pendiente en el área y elegir la persona más adelante.</p></div><div className="space-y-2"><Label htmlFor={`${prefix}-primary`} className="text-gray-900 font-semibold">Responsable principal</Label><select id={`${prefix}-primary`} className="w-full border rounded-md bg-white p-2" value={taskForm.primary_user} onChange={e=>setPrimaryUser(e.target.value)}><option value="">Sin responsable principal</option>{executorEmployees.map(e=><option key={e.id} value={e.id}>{workloadText(e)}</option>)}</select><p className="text-xs text-gray-500">Dirige la ejecución. La carga muestra los próximos 14 días y solo orienta; no asigna automáticamente.</p></div><div className="grid sm:grid-cols-2 gap-4"><div><Label className="text-gray-900 font-semibold">Colaboradores</Label><div className="border rounded-md p-3 mt-2 max-h-40 overflow-y-auto space-y-2">{executorEmployees.map(e=><label key={e.id} className="flex items-start gap-2 text-sm"><Checkbox checked={taskForm.collaborators.includes(e.id)} disabled={taskForm.primary_user===e.id} onCheckedChange={()=>togglePersonRole('collaborators',e.id)}/><span>{workloadText(e)}</span></label>)}</div><p className="text-xs text-gray-500 mt-1">Pueden ejecutar y fichar.</p></div><div><Label className="text-gray-900 font-semibold">Seguidores</Label><div className="border rounded-md p-3 mt-2 max-h-40 overflow-y-auto space-y-2">{employees.map(e=><label key={e.id} className="flex items-center gap-2 text-sm"><Checkbox checked={taskForm.followers.includes(e.id)} disabled={taskForm.primary_user===e.id} onCheckedChange={()=>togglePersonRole('followers',e.id)}/>{e.full_name}</label>)}</div><p className="text-xs text-gray-500 mt-1">Consultan y reciben avisos; no fichan.</p></div></div></div>
  const evidenceFields = prefix => <div className="space-y-2"><Label className="text-gray-900 font-semibold">Evidencias obligatorias para finalizar</Label><div className="grid sm:grid-cols-2 gap-2 border rounded-md p-3">{[['require_comment','Comentario'],['require_photo','Foto'],['require_video','Vídeo'],['require_file','Archivo']].map(([field,label])=><label key={field} className="flex items-center gap-2 text-sm"><Checkbox id={`${prefix}-${field}`} checked={taskForm[field]} onCheckedChange={checked=>setTaskForm(v=>({...v,[field]:checked===true}))}/>{label}</label>)}</div><p className="text-xs text-gray-500">El empleado deberá aportar lo marcado durante ese fichaje antes de poder finalizar.</p></div>
  const estimateField = prefix => <div className="space-y-2"><Label htmlFor={`${prefix}-estimate`} className="text-gray-900 font-semibold">Tiempo estimado (minutos)</Label><Input id={`${prefix}-estimate`} type="number" min="1" max="10080" value={taskForm.estimated_minutes} onChange={e=>setTaskForm(v=>({...v,estimated_minutes:e.target.value}))} placeholder="Sin estimación"/><p className="text-xs text-gray-500">Sirve para comparar la planificación con el tiempo real; no limita el fichaje.</p></div>
  const reviewField = prefix => <label className="flex items-start gap-3 rounded-md border p-3"><Checkbox id={`${prefix}-review`} checked={taskForm.requires_review} onCheckedChange={checked=>setTaskForm(v=>({...v,requires_review:checked===true}))}/><span><span className="font-semibold text-gray-900">Requiere aprobación del encargado</span><span className="block text-xs text-gray-500 mt-1">Al finalizar quedará En revisión hasta que se apruebe o se devuelva.</span></span></label>
  const resultField = prefix => <label className="flex items-start gap-3 rounded-md border p-3"><Checkbox id={`${prefix}-result`} checked={taskForm.require_result} onCheckedChange={checked=>setTaskForm(v=>({...v,require_result:checked===true}))}/><span><span className="font-semibold text-gray-900">Exigir resultado al finalizar</span><span className="block text-xs text-gray-500 mt-1">El empleado deberá resumir qué hizo antes de cerrar la ejecución.</span></span></label>
  const labelsField = prefix => <div className="space-y-2"><Label htmlFor={`${prefix}-labels`} className="text-gray-900 font-semibold">Etiquetas</Label><Input id={`${prefix}-labels`} value={taskForm.labels_text} onChange={e=>setTaskForm(v=>({...v,labels_text:e.target.value}))} placeholder="Ej.: Piscina, Cliente VIP, Preventivo"/><p className="text-xs text-gray-500">Separa las etiquetas con comas. Máximo 10; cada una puede tener hasta 40 caracteres.</p></div>
  const contextFields = prefix => <details className="rounded-md border p-3"><summary className="cursor-pointer font-semibold text-gray-900">Ubicación y origen relacionado</summary><div className="mt-4 space-y-4"><div className="space-y-2"><Label htmlFor={`${prefix}-location`}>Ubicación del trabajo</Label><Input id={`${prefix}-location`} value={taskForm.location} onChange={e=>setTaskForm(v=>({...v,location:e.target.value}))} maxLength={200} placeholder="Ej.: Planta 2 · Habitación 204"/></div><div className="grid sm:grid-cols-2 gap-4"><div className="space-y-2"><Label htmlFor={`${prefix}-source`}>Módulo de origen</Label><Input id={`${prefix}-source`} value={taskForm.source_module} onChange={e=>setTaskForm(v=>({...v,source_module:e.target.value}))} maxLength={60} placeholder="Ej.: Mantenimiento"/></div><div className="space-y-2"><Label htmlFor={`${prefix}-entity-type`}>Tipo de entidad</Label><Input id={`${prefix}-entity-type`} value={taskForm.related_entity_type} onChange={e=>setTaskForm(v=>({...v,related_entity_type:e.target.value}))} maxLength={60} placeholder="Ej.: Activo"/></div><div className="space-y-2"><Label htmlFor={`${prefix}-entity-reference`}>Referencia</Label><Input id={`${prefix}-entity-reference`} value={taskForm.related_entity_reference} onChange={e=>setTaskForm(v=>({...v,related_entity_reference:e.target.value}))} maxLength={120} placeholder="Ej.: AC-204"/></div><div className="space-y-2"><Label htmlFor={`${prefix}-entity-label`}>Nombre visible</Label><Input id={`${prefix}-entity-label`} value={taskForm.related_entity_label} onChange={e=>setTaskForm(v=>({...v,related_entity_label:e.target.value}))} maxLength={160} placeholder="Ej.: Aire acondicionado salón"/></div></div><p className="text-xs text-gray-500">El tipo y la referencia se completan juntos. Estos datos preparan la conexión con otros módulos sin cambiar la ejecución.</p></div></details>

  const filteredTasks = tasks.filter(t=>(t.title+' '+(t.description||'')+' '+(t.labels||[]).join(' ')+' '+[t.location,t.source_module,t.related_entity_type,t.related_entity_reference,t.related_entity_label].filter(Boolean).join(' ')).toLocaleLowerCase('es').includes(search.toLocaleLowerCase('es')) && (!employeeFilter||t.assigned_users.some(u=>u.id===employeeFilter)) && (statusFilter==='all'||t.status===statusFilter) && (importanceFilter==='all'||(t.importance||'normal')===importanceFilter))

  const getStatusBadge = (status) => {
    const variants = {
      pending: { bg: 'bg-yellow-100', text: 'text-yellow-800', label: 'Pendiente' },
      in_progress: { bg: 'bg-blue-100', text: 'text-blue-800', label: 'En Progreso' },
      completed: { bg: 'bg-green-100', text: 'text-green-800', label: 'Completada' }
    }
    const variant = variants[status] || variants.pending
    return <Badge className={`${variant.bg} ${variant.text} border-0`}>{variant.label}</Badge>
  }

  return (
    <Layout>
      {checklistTask&&<ChecklistEditor key={checklistTask.id} task={checklistTask} onClose={()=>setChecklistTask(null)}/>}
      <div className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Tareas</h1>
            <p className="text-gray-900 mt-1">Actividades, asignaciones y seguimiento del trabajo</p>
          </div>
        </div>

        <div className="flex flex-wrap justify-between gap-3"><div className={sectionTabsClass}><Button variant="outline" className={sectionTabClass(!query.get('tab'))} onClick={()=>setQuery({})}>Actividades</Button><Button variant="outline" className={sectionTabClass(query.get('tab')==='overdue')} onClick={()=>setQuery({tab:'overdue'})}>Tareas atrasadas</Button><Button variant="outline" className={sectionTabClass(query.get('tab')==='reviews')} onClick={()=>setQuery({tab:'reviews'})}>Revisiones</Button></div>{can('tasks.create') && <Button onClick={()=>{resetForm();fetchAssignmentLoad();setIsCreateModalOpen(true)}}><Plus className="w-4 h-4 mr-2"/>Crear tarea</Button>}</div>
        {query.get('tab')==='overdue' ? <TaskFollowup canPlan={can('planning.view')}/> : query.get('tab')==='reviews'?<ReviewQueue/>:<>
        <div className="grid md:grid-cols-3 gap-3"><Input aria-label="Buscar tareas" placeholder="Buscar actividad o descripción" value={search} onChange={e=>setSearch(e.target.value)}/><select aria-label="Filtrar por empleado" className="border rounded-md p-2 bg-white" value={employeeFilter} onChange={e=>setEmployeeFilter(e.target.value)}><option value="">Todos los empleados</option>{employees.map(e=><option key={e.id} value={e.id}>{e.full_name}</option>)}</select><select aria-label="Filtrar por estado general" className="border rounded-md p-2 bg-white" value={statusFilter} onChange={e=>setStatusFilter(e.target.value)}><option value="all">Todos los estados generales</option><option value="pending">Pendiente</option><option value="in_progress">En progreso</option><option value="completed">Completada</option></select></div>
        <p className="text-sm text-gray-500">Este catálogo define las actividades. Sus ejecuciones diarias y su orden se gestionan en Planificación.</p>
        <Card>
          <CardHeader>
            <CardTitle className="text-gray-900">Catálogo de actividades</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="mb-4 max-w-xs"><Label htmlFor="importance-filter">Filtrar por importancia</Label><select id="importance-filter" className="w-full border rounded-md bg-white p-2" value={importanceFilter} onChange={e=>setImportanceFilter(e.target.value)}><option value="all">Todas</option><option value="low">Baja</option><option value="normal">Normal</option><option value="high">Alta</option><option value="urgent">Urgente</option></select></div>
            {loading ? (
              <div className="text-center py-8">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
                <p className="mt-4 text-gray-900">Cargando tareas...</p>
              </div>
            ) : filteredTasks.length === 0 ? (
              <div className="text-center py-12">
                <CheckSquare className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-900 mb-4">{tasks.length?'No hay tareas con estos filtros':'No hay tareas creadas'}</p>
                {can('tasks.create') && <Button onClick={() => setIsCreateModalOpen(true)}>Crear Primera Tarea</Button>}
              </div>
            ) : (
              <>
              <MobileTasks items={filteredTasks} statusBadge={getStatusBadge} can={can} isAdmin={isAdmin} onShare={task=>navigate('/admin/access?task='+task.id)} onPlan={task=>navigate('/admin/planning'+(task.assigned_users[0]?'?employee='+task.assigned_users[0].id:''))} onChecklist={setChecklistTask} onDuplicate={handleDuplicateTask} onEdit={openEditModal} onDelete={handleDeleteTask}/>
              <div className="hidden md:block rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-gray-900">Título</TableHead>
                      <TableHead className="text-gray-900">Tipo</TableHead>
                      <TableHead className="text-gray-900">Fecha</TableHead>
                      <TableHead className="text-gray-900">Asignados</TableHead>
                      <TableHead className="text-gray-900">Estado general</TableHead>
                      <TableHead className="text-right text-gray-900">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredTasks.map((task) => (
                      <TableRow key={task.id}>
                        <TableCell className="font-medium text-gray-900"><p>{task.title}</p><div className="mt-2 flex flex-wrap gap-1"><ImportanceBadge value={task.importance}/>{(task.labels||[]).map(label=><Badge key={label} className="border border-cyan-200 bg-cyan-50 text-cyan-800">{label}</Badge>)}</div>{task.location&&<p className="mt-2 text-xs text-gray-600">📍 {task.location}</p>}{(task.source_module||task.related_entity_reference)&&<p className="mt-1 text-xs text-gray-600">Origen: {[task.source_module,task.related_entity_type,task.related_entity_reference,task.related_entity_label].filter(Boolean).join(' · ')}</p>}</TableCell>
                        <TableCell className="text-gray-900">
                          {task.schedule_type === 'daily' && '🔄 Diaria'}
                          {task.schedule_type === 'weekly' && '📅 Semanal'}
                          {task.schedule_type === 'monthly' && '📆 Mensual'}
                          {task.schedule_type === 'custom_date' && '📅 Fecha específica'}
                        </TableCell>
                        <TableCell className="text-gray-900">
                          {task.schedule_date ? format(new Date(task.schedule_date), 'PPP', { locale: es }) : '-'}
                        </TableCell>
                        <TableCell className="text-gray-900">{task.assigned_names}</TableCell>
                        <TableCell>{getStatusBadge(task.status)}</TableCell>
                        <TableCell className="text-right space-x-2">
                          {isAdmin && <Button size="sm" variant="outline" onClick={()=>navigate('/admin/access?task='+task.id)}>Compartir acceso</Button>}
                          {can('planning.view') && <Button size="sm" variant="outline" onClick={()=>navigate('/admin/planning'+(task.assigned_users[0]?'?employee='+task.assigned_users[0].id:''))}>Planificar</Button>}
                          {can('tasks.edit') && <Button size="sm" variant="outline" onClick={()=>setChecklistTask(task)}>Pasos</Button>}
                          {can('tasks.create') && <Button size="sm" variant="outline" aria-label={`Duplicar ${task.title}`} onClick={()=>handleDuplicateTask(task)}><Copy className="h-4 w-4"/></Button>}
                          {can('tasks.edit') && <Button size="sm" variant="outline" aria-label={`Editar ${task.title}`} onClick={() => openEditModal(task)}><Edit className="h-4 w-4" /></Button>}
                          {can('tasks.delete') && <Button size="sm" variant="outline" aria-label={`Eliminar ${task.title}`} onClick={() => handleDeleteTask(task.id)} className="text-red-600 hover:text-red-700"><Trash2 className="h-4 w-4" /></Button>}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
              </>
            )}
          </CardContent>
        </Card>
        </>}
      </div>

      <Dialog open={isCreateModalOpen} onOpenChange={setIsCreateModalOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle className="text-gray-900">Crear Nueva Tarea</DialogTitle>
            <DialogDescription className="text-gray-900">Completa los datos de la nueva tarea</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleCreateTask} className="space-y-4">
            <ImportanceField id="task-importance" value={taskForm.importance} onChange={importance=>setTaskForm(v=>({...v,importance}))}/>
            <div className="space-y-2">
              <Label htmlFor="title" className="text-gray-900 font-semibold">Título *</Label>
              <Input id="title" value={taskForm.title} onChange={(e) => setTaskForm(prev => ({ ...prev, title: e.target.value }))} required className="text-gray-900" />
            </div>

            <div className="space-y-2">
              <Label htmlFor="description" className="text-gray-900 font-semibold">Descripción</Label>
              <Textarea id="description" value={taskForm.description} onChange={(e) => setTaskForm(prev => ({ ...prev, description: e.target.value }))} rows={3} className="text-gray-900" />
            </div>
            {labelsField('create-task')}
            {contextFields('create-task')}

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="schedule_type" className="text-gray-900 font-semibold">Tipo de programación *</Label>
                <Select value={taskForm.schedule_type} onValueChange={(value) => setTaskForm(prev => ({ ...prev, schedule_type: value }))}>
                  <SelectTrigger className="text-gray-900">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="daily">Diaria</SelectItem>
                    <SelectItem value="weekly">Semanal</SelectItem>
                    <SelectItem value="monthly">Mensual</SelectItem>
                    <SelectItem value="custom_date">Fecha específica</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {taskForm.schedule_type === 'custom_date' && (
                <div className="space-y-2">
                  <Label htmlFor="schedule_date" className="text-gray-900 font-semibold">Fecha *</Label>
                  <Input id="schedule_date" type="date" value={taskForm.schedule_date} onChange={(e) => setTaskForm(prev => ({ ...prev, schedule_date: e.target.value }))} required className="text-gray-900" />
                </div>
              )}
            </div>

            {peopleFields('create-task')}
            {evidenceFields('create-task')}
            {estimateField('create-task')}
            {reviewField('create-task')}
            {resultField('create-task')}

            <Button type="submit" disabled={!can('tasks.create')} className="w-full">Crear Tarea</Button>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={isEditModalOpen} onOpenChange={setIsEditModalOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle className="text-gray-900">Editar Tarea</DialogTitle>
            <DialogDescription className="text-gray-900">Modifica los datos de la tarea</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleEditTask} className="space-y-4">
            <ImportanceField id="edit-task-importance" value={taskForm.importance} onChange={importance=>setTaskForm(v=>({...v,importance}))}/>
            {selectedTask&&<TaskTimeline key={selectedTask.id} taskId={selectedTask.id}/>}
            <div className="space-y-2">
              <Label htmlFor="edit-title" className="text-gray-900 font-semibold">Título *</Label>
              <Input id="edit-title" value={taskForm.title} onChange={(e) => setTaskForm(prev => ({ ...prev, title: e.target.value }))} required className="text-gray-900" />
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-description" className="text-gray-900 font-semibold">Descripción</Label>
              <Textarea id="edit-description" value={taskForm.description} onChange={(e) => setTaskForm(prev => ({ ...prev, description: e.target.value }))} rows={3} className="text-gray-900" />
            </div>
            {labelsField('edit-task')}
            {contextFields('edit-task')}

            <div className="space-y-2">
              <Label htmlFor="edit-status" className="text-gray-900 font-semibold">Estado *</Label>
              <Select value={taskForm.status} onValueChange={(value) => setTaskForm(prev => ({ ...prev, status: value }))}>
                <SelectTrigger className="text-gray-900">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pending">Pendiente</SelectItem>
                  <SelectItem value="in_progress">En Progreso</SelectItem>
                  <SelectItem value="completed">Completada</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {peopleFields('edit-task')}
            {evidenceFields('edit-task')}
            {estimateField('edit-task')}
            {reviewField('edit-task')}
            {resultField('edit-task')}

            <Button type="submit" disabled={!can('tasks.edit')} className="w-full">Guardar Cambios</Button>
          </form>
        </DialogContent>
      </Dialog>
    </Layout>
  )
}
export function AdminCharts({employees, revision}) {
  const today=workDate()
  const [start,setStart]=useState(()=>{const d=new Date(today+'T12:00:00Z');d.setUTCDate(d.getUTCDate()-29);return d.toISOString().slice(0,10)})
  const [end,setEnd]=useState(today),[employee,setEmployee]=useState(''),[data,setData]=useState(null),[error,setError]=useState(''),[busy,setBusy]=useState(false),[refresh,setRefresh]=useState(0)
  useEffect(()=>{
    let cancelled=false
    setBusy(true);setData(null);setError('')
    const span=(new Date(end+'T12:00:00Z')-new Date(start+'T12:00:00Z'))/86400000
    if(!start || !end || !Number.isFinite(span) || span<0 || span>365){setError('Selecciona un período de hasta 366 días.');setBusy(false);return}
    workRpc('work_admin_metrics',{p_start:start,p_end:end,p_user:employee || null}).then(result=>{if(!cancelled)setData(result)}).catch(e=>{if(!cancelled)setError(e.code==='PGRST202'?'Instala el archivo 13-GRAFICAS-ADMINISTRADOR.sql en Supabase para habilitar las gráficas.':e.message)}).finally(()=>{if(!cancelled)setBusy(false)})
    return()=>{cancelled=true}
  },[start,end,employee,revision,refresh])
  const hours=s=>`${(Number(s)/3600).toLocaleString('es-ES',{maximumFractionDigits:1})} h`
  const states=data?.states
  const maxDay=Math.max(1,...(data?.days || []).map(d=>Number(d.total)))
  const maxHours=Math.max(1,...(data?.employees || []).map(e=>Number(e.seconds)))
  return <section aria-label="Gráficas de planificación" className="space-y-4">
    <Card><CardHeader><CardTitle>Resumen de actividad</CardTitle></CardHeader><CardContent className="space-y-4">
      <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4"><div className="space-y-2"><Label htmlFor="chart-start">Desde</Label><Input id="chart-start" type="date" value={start} onChange={e=>setStart(e.target.value)}/></div><div className="space-y-2"><Label htmlFor="chart-end">Hasta</Label><Input id="chart-end" type="date" value={end} onChange={e=>setEnd(e.target.value)}/></div><div className="space-y-2"><Label htmlFor="chart-employee">Empleado</Label><select id="chart-employee" className="w-full border rounded-md bg-white p-2" value={employee} onChange={e=>setEmployee(e.target.value)}><option value="">Todos los empleados</option>{employees.map(e=><option key={e.id} value={e.id}>{e.full_name}</option>)}</select></div><div className="flex items-end"><Button variant="outline" disabled={busy} onClick={()=>setRefresh(n=>n+1)}>Actualizar gráficas</Button></div></div>
      <p className="text-sm text-gray-500">Tareas por fecha planificada y empleado. Las horas corresponden al tiempo registrado dentro del período (hora de Madrid), incluyendo fichajes anteriores al modo tablet.</p>
      {busy && <p role="status">Cargando gráficas…</p>}{error && <p role="alert" className="rounded-lg bg-red-50 text-red-800 p-3">{error}</p>}
      {states && <><div className="grid grid-cols-1 min-[420px]:grid-cols-2 lg:grid-cols-4 gap-4">{[['Planificadas',states.total,'border-blue-200 bg-blue-50 text-blue-800'],['Completadas',states.completed,'border-emerald-200 bg-emerald-50 text-emerald-800'],['Atrasadas',states.overdue,'border-rose-200 bg-rose-50 text-rose-800'],['Horas registradas',hours(data.employees.reduce((n,e)=>n+Number(e.seconds),0)),'border-violet-200 bg-violet-50 text-violet-800']].map(([label,value,color])=><div key={label} className={`border rounded-lg p-4 ${color}`}><p className="text-sm font-medium opacity-80">{label}</p><p className="text-2xl font-semibold mt-1">{value}</p></div>)}</div>{Number(states.total)===0 && <p className="text-gray-500">Sin tareas planificadas en el período. Se muestran las horas registradas si existen.</p>}<p className="text-xs text-gray-500">Actualizado: {new Date(data.as_of).toLocaleString('es-ES',{timeZone:'Europe/Madrid'})}. Pulsa Actualizar gráficas para refrescar los datos.</p></>}
    </CardContent></Card>
    {states && <><div className="grid lg:grid-cols-2 gap-4">
      <Card><CardHeader><CardTitle>Estado de las tareas</CardTitle></CardHeader><CardContent className="space-y-4">{[['Pendientes',states.pending,'#94A3B8'],['En curso',states.active,'#2F6BFF'],['Completadas',states.completed,'#22C55E']].map(([name,value,color])=><div key={name}><div className="flex justify-between text-sm mb-2"><span>{name}</span><span>{value}</span></div><div role="meter" aria-label={name} aria-valuenow={Number(value)} aria-valuemin={0} aria-valuemax={Math.max(1,Number(states.total))} className="h-3 rounded-full bg-gray-100 overflow-hidden"><div className="h-full rounded-full" style={{width:`${Number(states.total)?Number(value)/Number(states.total)*100:0}%`,background:color}}/></div></div>)}<p className="text-sm text-red-700">{states.overdue} atrasadas dentro de las pendientes o en curso.</p><p className="text-sm text-gray-500">{states.late} completadas fuera de plazo.</p></CardContent></Card>
      <Card><CardHeader><CardTitle>Horas por empleado</CardTitle></CardHeader><CardContent className="space-y-4 max-h-96 overflow-y-auto">{data.employees.length===0 && <p>Sin empleados para mostrar.</p>}{data.employees.map(e=><div key={e.id}><div className="flex flex-wrap justify-between gap-2 text-sm mb-2"><span>{e.name}</span><span className="whitespace-nowrap">{hours(e.seconds)}</span></div><div className="h-3 bg-gray-100 rounded-full overflow-hidden"><div className="h-full bg-blue-600 rounded-full" style={{width:`${Number(e.seconds)/maxHours*100}%`}}/></div><p className="text-xs text-gray-500 mt-1">{e.completed}/{e.total} tareas completadas · {e.overdue} atrasadas{Number(e.open)>0?` · ${e.open} fichajes abiertos incluidos hasta la actualización`:''}</p></div>)}</CardContent></Card>
    </div>
    <Card><CardHeader><CardTitle>Evolución diaria</CardTitle></CardHeader><CardContent className="space-y-3"><div className="flex flex-wrap gap-4 text-sm"><span><span className="inline-block w-3 h-3 bg-amber-500 mr-2"/>Planificadas</span><span><span className="inline-block w-3 h-3 bg-emerald-600 mr-2"/>Completadas</span></div><div className="overflow-x-auto"><svg role="img" aria-label="Tareas planificadas y completadas por fecha. Valores disponibles en la tabla inferior." viewBox={`0 0 ${Math.max(600,data.days.length*32)} 210`} style={{width:Math.max(600,data.days.length*32),height:210}}><line x1="0" y1="170" x2={Math.max(600,data.days.length*32)} y2="170" stroke="#E5EAF2"/>{data.days.map((d,i)=>{const step=Math.max(600,data.days.length*32)/data.days.length,x=i*step+step/2;return <g key={d.date}><title>{d.date}: {d.total} planificadas, {d.completed} completadas</title><rect x={x-9} y={170-Number(d.total)/maxDay*140} width="8" height={Number(d.total)/maxDay*140} fill="#F59E0B" rx="2"/><rect x={x+1} y={170-Number(d.completed)/maxDay*140} width="8" height={Number(d.completed)/maxDay*140} fill="#059669" rx="2"/><text x={x} y="190" textAnchor="middle" fontSize="9" fill="#667085">{d.date.slice(8)}/{d.date.slice(5,7)}</text></g>})}</svg></div><details><summary className="text-sm text-blue-700 cursor-pointer">Ver valores por día</summary><div className="max-h-64 overflow-auto mt-3"><table className="w-full text-sm text-left"><caption className="sr-only">Evolución diaria de tareas</caption><thead><tr><th className="p-2">Fecha</th><th>Planificadas</th><th>Completadas</th><th>Atrasadas</th></tr></thead><tbody>{data.days.map(d=><tr key={d.date} className="border-t"><td className="p-2">{d.date}</td><td>{d.total}</td><td>{d.completed}</td><td>{d.overdue}</td></tr>)}</tbody></table></div></details></CardContent></Card></>}
  </section>
}
