import { useAuth } from '@/hooks/useAuth'
import { useTasks } from '@/hooks/useTasks'
import Layout from '@/components/layout/Layout'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Calendar, Users, Clock, MapPin, Lock } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { Alert, AlertDescription } from '@/components/ui/alert'

export default function EmployeeDashboard() {
  const { userData } = useAuth()
  const { tasks, loading } = useTasks(userData?.id)

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
      pending: { bg: 'bg-yellow-100', text: 'text-yellow-800', icon: '⏳', label: 'Pendiente' },
      in_progress: { bg: 'bg-blue-100', text: 'text-blue-800', icon: '🔄', label: 'En Progreso' },
      completed: { bg: 'bg-green-100', text: 'text-green-800', icon: '✅', label: 'Completada' }
    }
    const variant = variants[status] || variants.pending

    return (
      <Badge className={`${variant.bg} ${variant.text} border-0`}>
        {variant.icon} {variant.label}
      </Badge>
    )
  }

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
            <p className="mt-4 text-gray-600">Cargando tus tareas...</p>
          </div>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-3xl font-bold text-gray-900">👋 Hola, {userData?.full_name}</h1>
          <p className="text-gray-600 mt-1">Panel informativo de tus tareas asignadas</p>
        </div>

        {/* Alerta informativa */}
        <Alert className="bg-blue-50 border-blue-200">
          <Lock className="h-4 w-4 text-blue-600" />
          <AlertDescription className="text-blue-800">
            <strong>ℹ️ Panel informativo:</strong> Esta es una vista general de tus tareas. Para trabajar en una tarea, necesitas acceder mediante la URL única proporcionada por tu supervisor.
          </AlertDescription>
        </Alert>

        {/* Estadísticas Personales */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-4xl font-bold text-green-600">{stats.total}</div>
                <p className="text-sm text-gray-600 mt-2">Total Tareas</p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-4xl font-bold text-yellow-600">{stats.pending}</div>
                <p className="text-sm text-gray-600 mt-2">Pendientes</p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-4xl font-bold text-blue-600">{stats.in_progress}</div>
                <p className="text-sm text-gray-600 mt-2">En Progreso</p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-4xl font-bold text-purple-600">{stats.completed}</div>
                <p className="text-sm text-gray-600 mt-2">Completadas</p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Mis Tareas - SOLO VISTA (SIN ACCIONES) */}
        <div>
          <div className="flex items-center gap-2 mb-4">
            <h2 className="text-2xl font-bold text-gray-900">📋 Mis Tareas Asignadas</h2>
            <Badge variant="outline" className="bg-gray-100 text-gray-600">
              Solo vista
            </Badge>
          </div>

          {tasks.length === 0 ? (
            <Card>
              <CardContent className="pt-12 pb-12">
                <div className="text-center">
                  <div className="text-6xl mb-4">📋</div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">
                    No tienes tareas asignadas
                  </h3>
                  <p className="text-gray-600">
                    Contacta con tu supervisor para que te asigne nuevas tareas
                  </p>
                </div>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {tasks.map((task) => (
                <Card key={task.id} className="border-2">
                  <CardHeader className="bg-gradient-to-r from-gray-50 to-gray-100">
                    <div className="flex items-start justify-between">
                      <CardTitle className="text-lg text-gray-900">{task.title}</CardTitle>
                      {getStatusBadge(task.status)}
                    </div>
                  </CardHeader>
                  <CardContent className="pt-4 space-y-3">
                    <p className="text-sm text-gray-600 line-clamp-2">
                      {task.description || 'Sin descripción'}
                    </p>

                    <div className="space-y-2">
                      {task.schedule_date && (
                        <div className="flex items-center gap-2 text-sm text-gray-600">
                          <Calendar className="h-4 w-4" />
                          <span>{format(new Date(task.schedule_date), 'PPP', { locale: es })}</span>
                        </div>
                      )}

                      <div className="flex items-center gap-2 text-sm text-gray-600">
                        <Users className="h-4 w-4" />
                        <span className="line-clamp-1">{task.assigned_names}</span>
                      </div>

                      {task.last_checkin && (
                        <div className="flex items-center gap-2 text-sm text-green-600">
                          <Clock className="h-4 w-4" />
                          <span>Último fichaje: {format(new Date(task.last_checkin), 'Pp', { locale: es })}</span>
                        </div>
                      )}

                      {task.expected_latitude && task.expected_longitude && (
                        <div className="flex items-center gap-2 text-sm text-blue-600">
                          <MapPin className="h-4 w-4" />
                          <span>GPS activado</span>
                        </div>
                      )}
                    </div>

                    {/* Tipo de Programación */}
                    <div className="pt-2 border-t">
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-gray-500">Tipo:</span>
                        <Badge variant="outline" className="text-xs">
                          {task.schedule_type === 'daily' && '🔄 Diaria'}
                          {task.schedule_type === 'weekly' && '📅 Semanal'}
                          {task.schedule_type === 'monthly' && '📆 Mensual'}
                          {task.schedule_type === 'custom_date' && '📅 Fecha Específica'}
                        </Badge>
                      </div>
                    </div>

                    {/* Indicador de acceso restringido */}
                    <div className="pt-2 border-t">
                      <div className="flex items-center justify-center gap-2 text-xs text-gray-500 bg-gray-50 py-2 rounded">
                        <Lock className="h-3 w-3" />
                        <span>Acceso mediante URL única</span>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>
      </div>
    </Layout>
  )
}