import { useState } from 'react'
import Layout from '@/components/layout/Layout'
import TaskCard from '@/components/employee/TaskCard'
import TaskDetail from '@/components/employee/TaskDetail'
import { useTasks } from '@/hooks/useTasks'
import { useAuth } from '@/hooks/useAuth'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { QrCode, CheckSquare, Clock, AlertCircle } from 'lucide-react'

export default function EmployeeDashboard() {
  const { user } = useAuth()
  const { tasks, loading } = useTasks(user?.id)
  const [selectedTask, setSelectedTask] = useState(null)
  const [isDetailOpen, setIsDetailOpen] = useState(false)

  const handleViewTask = (task) => {
    setSelectedTask(task)
    setIsDetailOpen(true)
  }

  const handleCloseDetail = () => {
    setIsDetailOpen(false)
    setSelectedTask(null)
  }

  // Estadísticas del empleado
  const stats = {
    total: tasks.length,
    pending: tasks.filter(t => t.status === 'pending').length,
    inProgress: tasks.filter(t => t.status === 'in_progress').length,
    completed: tasks.filter(t => t.status === 'completed').length
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
          <h1 className="text-3xl font-bold">Mis Tareas</h1>
          <p className="text-muted-foreground">
            Gestiona y consulta tus tareas asignadas
          </p>
        </div>

        {/* Acción Rápida */}
        <Card className="bg-gradient-to-r from-green-500 to-emerald-500 text-white border-0">
          <CardHeader>
            <CardTitle className="text-white text-xl">📱 Acción Rápida</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-white/90">
              Escanea el código QR de tu tarea para registrar tu fichaje
            </p>
            <Button 
              size="lg" 
              className="bg-white text-green-600 hover:bg-gray-100"
              onClick={() => window.location.href = '/employee/scan'}
            >
              <QrCode className="mr-2 h-5 w-5" />
              Escanear QR
            </Button>
          </CardContent>
        </Card>

        {/* Estadísticas */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total de Tareas</CardTitle>
              <CheckSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.total}</div>
              <p className="text-xs text-muted-foreground mt-1">
                Tareas asignadas
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Pendientes</CardTitle>
              <Clock className="h-4 w-4 text-yellow-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.pending}</div>
              <p className="text-xs text-muted-foreground mt-1">
                Por realizar
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">En Progreso</CardTitle>
              <AlertCircle className="h-4 w-4 text-orange-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.inProgress}</div>
              <p className="text-xs text-muted-foreground mt-1">
                En proceso
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Completadas</CardTitle>
              <CheckSquare className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.completed}</div>
              <p className="text-xs text-muted-foreground mt-1">
                Finalizadas
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Banner Informativo */}
        <Card className="bg-blue-50 border-blue-200">
          <CardContent className="pt-6">
            <div className="flex items-start gap-3">
              <div className="text-2xl">ℹ️</div>
              <div>
                <h3 className="font-semibold text-blue-900 mb-1">
                  Panel de Consulta de Tareas
                </h3>
                <p className="text-sm text-blue-800">
                  Aquí puedes ver todas las tareas que te han sido asignadas. Esta es una vista de solo lectura para que consultes tu agenda de trabajo.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Listado de Tareas */}
        <div>
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-2xl font-bold">Listado de Tareas</h2>
            <Badge variant="outline" className="text-sm">
              {tasks.length} tarea{tasks.length !== 1 ? 's' : ''}
            </Badge>
          </div>

          {tasks.length === 0 ? (
            <Card>
              <CardContent className="text-center py-12">
                <div className="text-6xl mb-4">📭</div>
                <h3 className="text-xl font-semibold mb-2">No tienes tareas asignadas</h3>
                <p className="text-muted-foreground">
                  Cuando el administrador te asigne tareas, aparecerán aquí para que puedas consultarlas.
                </p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {tasks.map((task) => (
                <TaskCard 
                  key={task.id} 
                  task={task} 
                  onView={handleViewTask}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Modal de Detalle */}
      <TaskDetail
        task={selectedTask}
        open={isDetailOpen}
        onClose={handleCloseDetail}
      />
    </Layout>
  )
}