import {ImportanceBadge} from '@/components/TaskImportance'
import {ScheduleText} from '@/components/planning/ExecutionSchedule'
import {useEffect, useRef, useState} from 'react'
import {supabase} from '@/lib/supabase'
import { useAuth } from '@/hooks/useAuth'
import { useTasks } from '@/hooks/useTasks'
import Layout from '@/components/layout/Layout'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Calendar, Users, Clock, MapPin, ArrowRight, ListTodo, Settings } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { useNavigate, useSearchParams } from 'react-router-dom'

export default function EmployeeDashboard() {
  const { userData } = useAuth()
  const { tasks, loading, error, fetchTasks } = useTasks(userData?.id)
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const requestedStatus = searchParams.get('status')
  const statusFilter = ['pending','in_progress','completed'].includes(requestedStatus) ? requestedStatus : 'all'
  const viewTitle = {all:'Mis tareas asignadas',pending:'Tareas pendientes',in_progress:'Tareas en progreso',completed:'Tareas completadas'}[statusFilter]
  const [day, setDay] = useState(null)
  const [dayError, setDayError] = useState('')
  const dayRequest=useRef(0)
  const loadDay = async () => {
    const request=++dayRequest.current
    try {
      const {data,error} = await supabase.rpc('work_mobile_queue')
      if(request!==dayRequest.current)return
      if(error){setDayError(['PGRST202','42883'].includes(error.code)?'Falta activar la actualización del orden de tareas en Supabase.':`No se pudo comprobar el orden de tareas (${error.code||'conexión'}): ${error.message||'Sin respuesta del servidor'}`);return}
      setDay(data);setDayError(false)
    }catch{if(request===dayRequest.current)setDayError('No se pudo actualizar el estado de tus tareas. Vuelve a intentar.')}
  }
  useEffect(()=>{
    if(!userData?.id)return
    let live=true,running=false
    const refresh=async()=>{if(!live||running)return;running=true;try{await loadDay()}finally{running=false}}
    refresh();const onFocus=()=>{if(!document.hidden)refresh()};const interval=setInterval(onFocus,10000)
    window.addEventListener('focus',onFocus)
    return()=>{live=false;dayRequest.current++;clearInterval(interval);window.removeEventListener('focus',onFocus)}
  },[userData?.id])
  const queue = day?.items || []
  const allTasks = (day ? queue : tasks.map(t=>({task_id:t.id,title:t.title,state:'unplanned',can_start:false}))).map(item => ({...tasks.find(t => t.id===item.task_id),...item,id:item.task_id,executionId:item.plan_id||null,
    status:item.state==='active'?'in_progress':item.state==='completed'?'completed':'pending'}))



  const visibleTasks = allTasks.filter(task => statusFilter==='all' || task.status===statusFilter)

  const getStatusBadge = (status) => {
    const variants = {
      pending: {
        bg: 'bg-amber-100',
        text: 'text-amber-800',
        border: 'border-amber-200',
        label: 'Pendiente'
      },
      in_progress: {
        bg: 'bg-blue-100',
        text: 'text-blue-800',
        border: 'border-blue-200',
        label: 'En Progreso'
      },
      completed: {
        bg: 'bg-green-100',
        text: 'text-green-800',
        border: 'border-green-200',
        label: 'Completada'
      }
    }
    return variants[status] || variants.pending
  }

  const getScheduleTypeBadge = (type) => {
    const types = {
      daily: { icon: '🔄', label: 'Diaria', bg: 'bg-purple-100', text: 'text-purple-800' },
      weekly: { icon: '📅', label: 'Semanal', bg: 'bg-blue-100', text: 'text-blue-800' },
      monthly: { icon: '📆', label: 'Mensual', bg: 'bg-indigo-100', text: 'text-indigo-800' },
      custom_date: { icon: '📅', label: 'Fecha Específica', bg: 'bg-pink-100', text: 'text-pink-800' }
    }
    const config = types[type] || types.custom_date

    return (
      <Badge variant="outline" className={`${config.bg} ${config.text} border-0 text-xs`}>
        {config.icon} {config.label}
      </Badge>
    )
  }

  const handleViewTask = (task) => {
    const actionable = task.state==='active' || (task.executionId===day?.next_plan && task.can_start===true)
    const params=new URLSearchParams();if(task.executionId)params.set('plan',task.executionId);if(!actionable)params.set('view','history')
    navigate(`/employee/task/${task.id}/work${params.size?'?'+params.toString():''}`)
  }

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="text-center space-y-4">
            <div className="animate-spin rounded-full h-16 w-16 border-4 border-blue-500 border-t-transparent mx-auto"></div>
            <p className="text-gray-600 font-medium">Cargando tus tareas...</p>
          </div>
        </div>
      </Layout>
    )
  }

  if (error) {
    return (
      <Layout>
        <div className="space-y-4 max-w-7xl mx-auto">
          <Alert><AlertDescription>No se pudieron cargar tus tareas. Vuelve a intentarlo.</AlertDescription></Alert>
          <Button onClick={fetchTasks}>Volver a intentar</Button>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="space-y-8 max-w-7xl mx-auto">
        {/* Header con navegación */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-4">

            <div>
              <h1 className="text-4xl font-bold text-gray-900">
                Hola, <span className="text-blue-600">{userData?.full_name}</span> 👋
              </h1>
              <p className="text-gray-600 text-lg mt-1">
                {statusFilter==='all'?'Aquí están todas tus tareas asignadas':viewTitle}
              </p>
            </div>
          </div>
          <Button
            variant="outline"
            onClick={() => navigate('/employee/settings')}
            className="flex items-center gap-2"
          >
            <Settings className="h-4 w-4" />
            Configuración
          </Button>
        </div>

        {/* Lista de Tareas */}
        <div>
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-gray-900">{viewTitle}</h2>
            <Badge variant="outline" className="text-sm px-3 py-1">
              {visibleTasks.length} {visibleTasks.length === 1 ? 'tarea' : 'tareas'}
            </Badge>
          </div>

          {dayError && <Alert><AlertDescription>{dayError} <button className="underline" onClick={loadDay}>Reintentar</button></AlertDescription></Alert>}
          {!day && !dayError ? <p className="text-gray-600">Cargando planificación del día…</p> : visibleTasks.length === 0 ? (
            <Card className="border-2 border-dashed border-gray-300">
              <CardContent className="py-16">
                <div className="text-center space-y-4">
                  <div className="mx-auto w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center">
                    <ListTodo className="h-10 w-10 text-gray-400" />
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-gray-900 mb-2">
                      {statusFilter==='all'?'No tienes tareas asignadas':'No hay tareas en esta vista'}
                    </h3>
                    <p className="text-gray-600">
                      Selecciona otra opción en el menú para consultar tus tareas.
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {visibleTasks.map((task) => {
                const statusBadge = getStatusBadge(task.status)
                const actionable = task.state==='active' || (task.executionId===day?.next_plan && task.can_start===true)

                return (
                  <Card
                    key={task.executionId||task.id}
                    className="border-2 hover:shadow-lg transition-all duration-200 flex flex-col group"
                  >
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between gap-3 mb-3">
                        <CardTitle className="text-lg font-semibold text-gray-900 line-clamp-2 flex-1">
                          {task.title}
                        </CardTitle>
                      </div>

                      {/* Badges de estado y tipo */}
                      <div className="flex items-center gap-2 flex-wrap">
                        <Badge
                          variant="outline"
                          className={`${statusBadge.bg} ${statusBadge.text} ${statusBadge.border} border text-xs font-medium`}
                        >
                          {statusBadge.label}
                        </Badge>
                        <ImportanceBadge value={task.importance}/>{task.schedule_type && getScheduleTypeBadge(task.schedule_type)}
                        {task.priority != null && <Badge variant="outline">Orden {task.priority}</Badge>}
                        <Badge variant="outline">{task.state==='completed'?'Finalizada · solo consulta':task.state==='active'?'En curso':actionable?'Siguiente tarea · NFC habilitado':'Solo consulta'}</Badge>
                      </div>

                      <p className="text-sm text-gray-600 line-clamp-2 mt-2">
                        {task.description || 'Sin descripción'}
                      </p>
                      <ScheduleText item={task}/>
                    </CardHeader>

                    <CardContent className="space-y-4 flex-1 flex flex-col pt-0">
                      {/* Información de la tarea */}
                      <div className="space-y-2 flex-1">
                        {task.schedule_date && (
                          <div className="flex items-center gap-2 text-sm text-gray-700">
                            <Calendar className="h-4 w-4 text-gray-500 shrink-0" />
                            <span className="truncate">
                              {format(new Date(task.schedule_date), 'PPP', { locale: es })}
                            </span>
                          </div>
                        )}

                        <div className="flex items-center gap-2 text-sm text-gray-700">
                          <Users className="h-4 w-4 text-gray-500 shrink-0" />
                          <span className="truncate">{task.assigned_names}</span>
                        </div>

                        {task.last_checkin && (
                          <div className="flex items-center gap-2 text-sm text-green-700">
                            <Clock className="h-4 w-4 text-green-600 shrink-0" />
                            <span className="truncate">
                              {format(new Date(task.last_checkin), 'Pp', { locale: es })}
                            </span>
                          </div>
                        )}

                        {task.expected_latitude && task.expected_longitude && (
                          <div className="flex items-center gap-2 text-sm text-blue-700">
                            <MapPin className="h-4 w-4 text-blue-600 shrink-0" />
                            <span>GPS activado</span>
                          </div>
                        )}
                      </div>

                      {/* CTA Button */}
                      <Button
                        onClick={() => handleViewTask(task)}
                        variant={actionable ? 'default' : 'outline'}
                        className={actionable ? 'w-full bg-blue-600 hover:bg-blue-700 text-white font-medium group-hover:shadow-lg transition-all' : 'w-full font-medium'}
                        size="lg"
                      >
                        {task.state==='active' ? 'Continuar tarea' : actionable ? 'Siguiente tarea · Fichar con NFC' : 'Ver historial y comentarios'}
                        <ArrowRight className="ml-2 h-4 w-4 group-hover:translate-x-1 transition-transform" />
                      </Button>
                    </CardContent>
                  </Card>
                )
              })}
            </div>
          )}
        </div>
        <div className="flex flex-wrap gap-3"><Button variant="outline" onClick={() => navigate('/incidents')}>Consultar incidencias</Button></div>
        {/* Alerta informativa */}
        <Alert className="bg-blue-50 border-blue-200 border-2">
          <AlertDescription className="text-blue-900">
            Solo puedes iniciar la siguiente tarea según el orden del encargado, o atender una incidencia que tengas asignada. Las finalizadas quedan al final para consulta.
          </AlertDescription>
        </Alert>

      </div>
    </Layout>
  )
}
