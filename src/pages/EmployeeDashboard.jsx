import { useAuth } from '@/hooks/useAuth'
import { useTasks } from '@/hooks/useTasks'
import Layout from '@/components/layout/Layout'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Calendar, Users, Clock, MapPin, ArrowRight, ListTodo, ArrowLeft, Settings } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { useNavigate } from 'react-router-dom'

export default function EmployeeDashboard() {
  const { userData } = useAuth()
  const { tasks, loading } = useTasks(userData?.id)
  const navigate = useNavigate()

  const getTaskStats = () => {
    return {
      total: tasks.length,
      pending: tasks.filter(t => t.status === 'pending').length,
      in_progress: tasks.filter(t => t.status === 'in_progress').length,
      completed: tasks.filter(t => t.status === 'completed').length
    }
  }

  const stats = getTaskStats()

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

  const handleViewTask = (taskId) => {
    // Navega a la página de detalle con acciones
    navigate(`/employee/task/${taskId}/work`)
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

  return (
    <Layout>
      <div className="space-y-8 max-w-7xl mx-auto">
        {/* Header con navegación */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button
              variant="outline"
              size="icon"
              onClick={() => navigate(-1)}
              className="shrink-0"
            >
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
              <h1 className="text-4xl font-bold text-gray-900">
                Hola, <span className="text-blue-600">{userData?.full_name}</span> 👋
              </h1>
              <p className="text-gray-600 text-lg mt-1">
                Aquí están tus tareas asignadas
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

        {/* Estadísticas */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card className="border-2 border-gray-200 hover:border-gray-300 transition-colors">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600 mb-1">Total</p>
                  <p className="text-3xl font-bold text-gray-900">{stats.total}</p>
                </div>
                <div className="h-12 w-12 bg-gray-100 rounded-full flex items-center justify-center">
                  <ListTodo className="h-6 w-6 text-gray-600" />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="border-2 border-amber-200 hover:border-amber-300 transition-colors bg-amber-50">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-amber-700 mb-1">Pendientes</p>
                  <p className="text-3xl font-bold text-amber-600">{stats.pending}</p>
                </div>
                <div className="h-12 w-12 bg-amber-200 rounded-full flex items-center justify-center">
                  <span className="text-2xl">⏳</span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="border-2 border-blue-200 hover:border-blue-300 transition-colors bg-blue-50">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-blue-700 mb-1">En Progreso</p>
                  <p className="text-3xl font-bold text-blue-600">{stats.in_progress}</p>
                </div>
                <div className="h-12 w-12 bg-blue-200 rounded-full flex items-center justify-center">
                  <span className="text-2xl">🔄</span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="border-2 border-green-200 hover:border-green-300 transition-colors bg-green-50">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-green-700 mb-1">Completadas</p>
                  <p className="text-3xl font-bold text-green-600">{stats.completed}</p>
                </div>
                <div className="h-12 w-12 bg-green-200 rounded-full flex items-center justify-center">
                  <span className="text-2xl">✓</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Alerta informativa */}
        <Alert className="bg-blue-50 border-blue-200 border-2">
          <AlertDescription className="text-blue-900">
            💡 <strong>Tip:</strong> Haz clic en "Ver detalle" para acceder a cada tarea y registrar tus fichajes.
          </AlertDescription>
        </Alert>

        {/* Lista de Tareas */}
        <div>
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-gray-900">Mis Tareas</h2>
            <Badge variant="outline" className="text-sm px-3 py-1">
              {tasks.length} {tasks.length === 1 ? 'tarea' : 'tareas'}
            </Badge>
          </div>

          {tasks.length === 0 ? (
            <Card className="border-2 border-dashed border-gray-300">
              <CardContent className="py-16">
                <div className="text-center space-y-4">
                  <div className="mx-auto w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center">
                    <ListTodo className="h-10 w-10 text-gray-400" />
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-gray-900 mb-2">
                      No tienes tareas asignadas
                    </h3>
                    <p className="text-gray-600">
                      Contacta con tu supervisor para que te asigne nuevas tareas
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {tasks.map((task) => {
                const statusBadge = getStatusBadge(task.status)
                
                return (
                  <Card 
                    key={task.id} 
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
                        {task.schedule_type && getScheduleTypeBadge(task.schedule_type)}
                      </div>
                      
                      <p className="text-sm text-gray-600 line-clamp-2 mt-2">
                        {task.description || 'Sin descripción'}
                      </p>
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
                        onClick={() => handleViewTask(task.id)}
                        className="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium group-hover:shadow-lg transition-all"
                        size="lg"
                      >
                        Ver detalle
                        <ArrowRight className="ml-2 h-4 w-4 group-hover:translate-x-1 transition-transform" />
                      </Button>
                    </CardContent>
                  </Card>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </Layout>
  )
}