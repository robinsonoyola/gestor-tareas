import {ImportanceBadge,ImportanceField,TaskTimeline} from '@/components/TaskImportance'
import ChecklistEditor from '@/components/checklists/ChecklistEditor'
import {MobileTasks} from './admin/MobileRecords'
import { useState, useEffect } from 'react'
import TaskFollowup from './admin/TaskFollowup'
import { useSearchParams } from 'react-router-dom'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { workDate, workRpc } from '@/lib/workflow'
import Layout from '@/components/layout/Layout'
import { Button } from '@/components/ui/button'
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
  const [loading, setLoading] = useState(true)
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
  const [isEditModalOpen, setIsEditModalOpen] = useState(false)
  const [checklistTask,setChecklistTask]=useState(null)
  const [selectedTask, setSelectedTask] = useState(null)
  
  const [taskForm, setTaskForm] = useState({
    title: '',
    description: '',
    schedule_type: 'daily',
    importance: 'normal',
    schedule_date: '',
    status: 'pending',
    assigned_users: []
  })

  useEffect(() => {
    fetchTasks()
    fetchEmployees()
  }, [])

  const fetchTasks = async () => {
    try {
      setLoading(true)
      const data = await workRpc('work_task_catalog')
      const tasksWithUsers = data.map(task=>({...task,assigned_names:task.assigned_users.map(u=>u.full_name).join(', ') || 'Sin asignar'}))
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

  const handleCreateTask = async (e) => {
    e.preventDefault()

    try {
      await workRpc('work_manage_task_importance',{p_importance:taskForm.importance||'normal',p_action:'create',p_title:taskForm.title,p_description:taskForm.description,p_schedule:taskForm.schedule_type,p_date:taskForm.schedule_date||null,p_status:taskForm.status,p_users:taskForm.assigned_users})
      toast.success('✅ Tarea creada correctamente')
      setIsCreateModalOpen(false)
      resetForm()
      fetchTasks()
    } catch (error) {
      console.error('Error creating task:', error)
      const message=String(error?.message||error||'')
      toast.error(message.includes('work_manage_task_importance')?'Falta activar la importancia de tareas en Supabase.':message||'Error al crear la tarea')
    }
  }

  const handleEditTask = async (e) => {
    e.preventDefault()

    try {
      await workRpc('work_manage_task_importance',{p_importance:taskForm.importance||'normal',p_action:'edit',p_id:selectedTask.id,p_title:taskForm.title,p_description:taskForm.description,p_schedule:taskForm.schedule_type,p_date:taskForm.schedule_date||null,p_status:taskForm.status,p_users:taskForm.assigned_users})
      toast.success('✅ Tarea actualizada correctamente')
      setIsEditModalOpen(false)
      setSelectedTask(null)
      resetForm()
      fetchTasks()
    } catch (error) {
      console.error('Error updating task:', error)
      const message=String(error?.message||error||'')
      toast.error(message.includes('work_manage_task_importance')?'Falta activar la importancia de tareas en Supabase.':message||'Error al actualizar la tarea')
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

  const openEditModal = (task) => {
    setSelectedTask(task)
    setTaskForm({
      title: task.title,
      description: task.description || '',
      schedule_type: task.schedule_type,
      importance: task.importance || 'normal',
      schedule_date: task.schedule_date || '',
      status: task.status,
      assigned_users: task.assigned_users.map(u => u.id)
    })
    setIsEditModalOpen(true)
  }

  const resetForm = () => {
    setTaskForm({
      title: '',
      description: '',
      schedule_type: 'daily',
      importance: 'normal',
      schedule_date: '',
      status: 'pending',
      assigned_users: []
    })
  }

  const toggleUserAssignment = (userId) => {
    setTaskForm(prev => ({
      ...prev,
      assigned_users: prev.assigned_users.includes(userId)
        ? prev.assigned_users.filter(id => id !== userId)
        : [...prev.assigned_users, userId]
    }))
  }

  const filteredTasks = tasks.filter(t=>(t.title+' '+(t.description||'')).toLocaleLowerCase('es').includes(search.toLocaleLowerCase('es')) && (!employeeFilter||t.assigned_users.some(u=>u.id===employeeFilter)) && (statusFilter==='all'||t.status===statusFilter) && (importanceFilter==='all'||(t.importance||'normal')===importanceFilter))

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

        <div className="flex flex-wrap justify-between gap-3"><div className="flex gap-2"><Button variant={query.get('tab')!=='overdue'?'default':'outline'} onClick={()=>setQuery({})}>Actividades</Button><Button variant={query.get('tab')==='overdue'?'default':'outline'} onClick={()=>setQuery({tab:'overdue'})}>Tareas atrasadas</Button></div>{can('tasks.create') && <Button onClick={()=>{resetForm();setIsCreateModalOpen(true)}}><Plus className="w-4 h-4 mr-2"/>Crear tarea</Button>}</div>
        {query.get('tab')==='overdue' ? <TaskFollowup canPlan={can('planning.view')}/> : <>
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
              <MobileTasks items={filteredTasks} statusBadge={getStatusBadge} can={can} isAdmin={isAdmin} onShare={task=>navigate('/admin/access?task='+task.id)} onPlan={task=>navigate('/admin/planning'+(task.assigned_users[0]?'?employee='+task.assigned_users[0].id:''))} onChecklist={setChecklistTask} onEdit={openEditModal} onDelete={handleDeleteTask}/>
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
                        <TableCell className="font-medium text-gray-900"><p>{task.title}</p><div className="mt-2"><ImportanceBadge value={task.importance}/></div></TableCell>
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

            <div className="space-y-2">
              <Label className="text-gray-900 font-semibold">Asignar a empleados</Label>
              <div className="border rounded-md p-4 max-h-48 overflow-y-auto space-y-2">
                {employees.map((employee) => (
                  <div key={employee.id} className="flex items-center space-x-2">
                    <Checkbox id={`emp-${employee.id}`} checked={taskForm.assigned_users.includes(employee.id)} onCheckedChange={() => toggleUserAssignment(employee.id)} />
                    <label htmlFor={`emp-${employee.id}`} className="text-sm text-gray-900 cursor-pointer">{employee.full_name}</label>
                  </div>
                ))}
              </div>
            </div>

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

            <div className="space-y-2">
              <Label className="text-gray-900 font-semibold">Asignar a empleados</Label>
              <div className="border rounded-md p-4 max-h-48 overflow-y-auto space-y-2">
                {employees.map((employee) => (
                  <div key={employee.id} className="flex items-center space-x-2">
                    <Checkbox id={`edit-emp-${employee.id}`} checked={taskForm.assigned_users.includes(employee.id)} onCheckedChange={() => toggleUserAssignment(employee.id)} />
                    <label htmlFor={`edit-emp-${employee.id}`} className="text-sm text-gray-900 cursor-pointer">{employee.full_name}</label>
                  </div>
                ))}
              </div>
            </div>

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
      {states && <><div className="grid grid-cols-1 min-[420px]:grid-cols-2 lg:grid-cols-4 gap-4">{[['Planificadas',states.total],['Completadas',states.completed],['Atrasadas',states.overdue],['Horas registradas',hours(data.employees.reduce((n,e)=>n+Number(e.seconds),0))]].map(([label,value])=><div key={label} className="border rounded-lg p-4"><p className="text-sm text-gray-500">{label}</p><p className="text-2xl font-semibold mt-1">{value}</p></div>)}</div>{Number(states.total)===0 && <p className="text-gray-500">Sin tareas planificadas en el período. Se muestran las horas registradas si existen.</p>}<p className="text-xs text-gray-500">Actualizado: {new Date(data.as_of).toLocaleString('es-ES',{timeZone:'Europe/Madrid'})}. Pulsa Actualizar gráficas para refrescar los datos.</p></>}
    </CardContent></Card>
    {states && <><div className="grid lg:grid-cols-2 gap-4">
      <Card><CardHeader><CardTitle>Estado de las tareas</CardTitle></CardHeader><CardContent className="space-y-4">{[['Pendientes',states.pending,'#94A3B8'],['En curso',states.active,'#2F6BFF'],['Completadas',states.completed,'#22C55E']].map(([name,value,color])=><div key={name}><div className="flex justify-between text-sm mb-2"><span>{name}</span><span>{value}</span></div><div role="meter" aria-label={name} aria-valuenow={Number(value)} aria-valuemin={0} aria-valuemax={Math.max(1,Number(states.total))} className="h-3 rounded-full bg-gray-100 overflow-hidden"><div className="h-full rounded-full" style={{width:`${Number(states.total)?Number(value)/Number(states.total)*100:0}%`,background:color}}/></div></div>)}<p className="text-sm text-red-700">{states.overdue} atrasadas dentro de las pendientes o en curso.</p><p className="text-sm text-gray-500">{states.late} completadas fuera de plazo.</p></CardContent></Card>
      <Card><CardHeader><CardTitle>Horas por empleado</CardTitle></CardHeader><CardContent className="space-y-4 max-h-96 overflow-y-auto">{data.employees.length===0 && <p>Sin empleados para mostrar.</p>}{data.employees.map(e=><div key={e.id}><div className="flex flex-wrap justify-between gap-2 text-sm mb-2"><span>{e.name}</span><span className="whitespace-nowrap">{hours(e.seconds)}</span></div><div className="h-3 bg-gray-100 rounded-full overflow-hidden"><div className="h-full bg-blue-600 rounded-full" style={{width:`${Number(e.seconds)/maxHours*100}%`}}/></div><p className="text-xs text-gray-500 mt-1">{e.completed}/{e.total} tareas completadas · {e.overdue} atrasadas{Number(e.open)>0?` · ${e.open} fichajes abiertos incluidos hasta la actualización`:''}</p></div>)}</CardContent></Card>
    </div>
    <Card><CardHeader><CardTitle>Evolución diaria</CardTitle></CardHeader><CardContent className="space-y-3"><div className="flex flex-wrap gap-4 text-sm"><span><span className="inline-block w-3 h-3 bg-gray-300 mr-2"/>Planificadas</span><span><span className="inline-block w-3 h-3 bg-blue-600 mr-2"/>Completadas</span></div><div className="overflow-x-auto"><svg role="img" aria-label="Tareas planificadas y completadas por fecha. Valores disponibles en la tabla inferior." viewBox={`0 0 ${Math.max(600,data.days.length*32)} 210`} style={{width:Math.max(600,data.days.length*32),height:210}}><line x1="0" y1="170" x2={Math.max(600,data.days.length*32)} y2="170" stroke="#E5EAF2"/>{data.days.map((d,i)=>{const step=Math.max(600,data.days.length*32)/data.days.length,x=i*step+step/2;return <g key={d.date}><title>{d.date}: {d.total} planificadas, {d.completed} completadas</title><rect x={x-9} y={170-Number(d.total)/maxDay*140} width="8" height={Number(d.total)/maxDay*140} fill="#CBD5E1" rx="2"/><rect x={x+1} y={170-Number(d.completed)/maxDay*140} width="8" height={Number(d.completed)/maxDay*140} fill="#2F6BFF" rx="2"/><text x={x} y="190" textAnchor="middle" fontSize="9" fill="#667085">{d.date.slice(8)}/{d.date.slice(5,7)}</text></g>})}</svg></div><details><summary className="text-sm text-blue-700 cursor-pointer">Ver valores por día</summary><div className="max-h-64 overflow-auto mt-3"><table className="w-full text-sm text-left"><caption className="sr-only">Evolución diaria de tareas</caption><thead><tr><th className="p-2">Fecha</th><th>Planificadas</th><th>Completadas</th><th>Atrasadas</th></tr></thead><tbody>{data.days.map(d=><tr key={d.date} className="border-t"><td className="p-2">{d.date}</td><td>{d.total}</td><td>{d.completed}</td><td>{d.overdue}</td></tr>)}</tbody></table></div></details></CardContent></Card></>}
  </section>
}
