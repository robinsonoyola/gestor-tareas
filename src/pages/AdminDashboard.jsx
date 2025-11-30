import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import Layout from '@/components/layout/Layout'
import Statistics from '@/components/admin/Statistics'
import TaskList from '@/components/admin/TaskList'
import TaskForm from '@/components/admin/TaskForm'
import EmployeeList from '@/components/admin/EmployeeList'
import { useTasks } from '@/hooks/useTasks'
import { useEmployees } from '@/hooks/useEmployees'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { Plus, ClipboardList, Users, QrCode, MapPin } from 'lucide-react'

export default function AdminDashboard() {
  const navigate = useNavigate()
  const { tasks, loading: tasksLoading, createTask, updateTask, deleteTask } = useTasks()
  const { employees, loading: employeesLoading, createEmployee, updateEmployee, deleteEmployee } = useEmployees()

  const [isTaskFormOpen, setIsTaskFormOpen] = useState(false)
  const [selectedTask, setSelectedTask] = useState(null)
  const [taskToDelete, setTaskToDelete] = useState(null)

  // Handlers de Tareas
  const handleCreateTask = () => {
    setSelectedTask(null)
    setIsTaskFormOpen(true)
  }

  const handleEditTask = (task) => {
    setSelectedTask(task)
    setIsTaskFormOpen(true)
  }

  const handleViewTask = (task) => {
    console.log('Ver tarea:', task)
  }

  const handleDeleteTask = (task) => {
    setTaskToDelete(task)
  }

  const confirmDeleteTask = async () => {
    if (taskToDelete) {
      const result = await deleteTask(taskToDelete.id)
      if (result.success) {
        toast.success('Tarea eliminada', {
          description: 'La tarea ha sido eliminada correctamente',
        })
      } else {
        toast.error('Error al eliminar', {
          description: result.error || 'No se pudo eliminar la tarea',
        })
      }
    }
    setTaskToDelete(null)
  }

  const handleTaskSubmit = async (formData) => {
    let result
    if (selectedTask) {
      result = await updateTask(selectedTask.id, formData)
    } else {
      result = await createTask(formData)
    }

    if (result.success) {
      toast.success(selectedTask ? 'Tarea actualizada' : 'Tarea creada', {
        description: selectedTask 
          ? 'Los cambios se han guardado correctamente'
          : 'La tarea ha sido creada correctamente',
      })
      setIsTaskFormOpen(false)
      setSelectedTask(null)
    } else {
      toast.error('Error', {
        description: result.error || 'No se pudo guardar la tarea',
      })
    }
  }

  // Handlers de Empleados
  const handleCreateEmployee = async (formData) => {
    const result = await createEmployee(formData)
    if (result.success) {
      toast.success('Empleado creado', {
        description: 'El empleado ha sido creado correctamente',
      })
    } else {
      toast.error('Error', {
        description: result.error || 'No se pudo crear el empleado',
      })
    }
  }

  const handleUpdateEmployee = async (id, formData) => {
    const result = await updateEmployee(id, formData)
    if (result.success) {
      toast.success('Empleado actualizado', {
        description: 'Los cambios se han guardado correctamente',
      })
    } else {
      toast.error('Error', {
        description: result.error || 'No se pudo actualizar el empleado',
      })
    }
  }

  const handleDeleteEmployee = async (id) => {
    const result = await deleteEmployee(id)
    if (result.success) {
      toast.success('Empleado eliminado', {
        description: 'El empleado ha sido eliminado correctamente',
      })
    } else {
      toast.error('Error', {
        description: result.error || 'No se pudo eliminar el empleado',
      })
    }
  }

  if (tasksLoading || employeesLoading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
            <p className="mt-4 text-gray-600">Cargando datos...</p>
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
          <h1 className="text-3xl font-bold">Panel de Administración</h1>
          <p className="text-muted-foreground">
            Gestiona las tareas, empleados y configuraciones del hotel
          </p>
        </div>

        {/* Estadísticas */}
        <Statistics tasks={tasks} />

        {/* Tabs */}
        <Tabs defaultValue="tasks" className="space-y-4">
          <TabsList className="bg-white">
            <TabsTrigger value="tasks">
              <ClipboardList className="mr-2 h-4 w-4" />
              Tareas
            </TabsTrigger>
            <TabsTrigger value="employees">
              <Users className="mr-2 h-4 w-4" />
              Empleados
            </TabsTrigger>
            <TabsTrigger value="qr">
              <QrCode className="mr-2 h-4 w-4" />
              Códigos QR
            </TabsTrigger>
            <TabsTrigger value="locations">
              <MapPin className="mr-2 h-4 w-4" />
              Ubicaciones GPS
            </TabsTrigger>
          </TabsList>

          {/* Tab: Tareas */}
          <TabsContent value="tasks" className="space-y-4">
            <div className="bg-white p-6 rounded-lg border">
              <div className="flex justify-between items-center mb-6">
                <div>
                  <h2 className="text-2xl font-bold">Gestión de Tareas</h2>
                  <p className="text-sm text-muted-foreground">
                    Crea, edita y administra las tareas del hotel
                  </p>
                </div>
                <Button onClick={handleCreateTask} size="lg" className="text-black">
                  <Plus className="mr-2 h-5 w-5" />
                  Nueva Tarea
                </Button>
              </div>

              <TaskList
                tasks={tasks}
                onEdit={handleEditTask}
                onDelete={handleDeleteTask}
                onView={handleViewTask}
              />
            </div>
          </TabsContent>

          {/* Tab: Empleados */}
          <TabsContent value="employees" className="space-y-4">
            <div className="bg-white p-6 rounded-lg border">
              <EmployeeList
                employees={employees}
                onCreate={handleCreateEmployee}
                onUpdate={handleUpdateEmployee}
                onDelete={handleDeleteEmployee}
              />
            </div>
          </TabsContent>

          {/* Tab: Códigos QR */}
          <TabsContent value="qr" className="space-y-4">
            <div className="bg-white p-12 rounded-lg border">
              <div className="text-center">
                <QrCode className="h-16 w-16 mx-auto text-muted-foreground mb-4" />
                <h3 className="text-xl font-semibold mb-2">Generador de Códigos QR</h3>
                <p className="text-muted-foreground mb-4">
                  Genera códigos QR para las tareas del hotel
                </p>
                <Button onClick={() => navigate('/admin/qr-generator')} size="lg" className="text-black">
                  Ir al Generador de QR
                </Button>
              </div>
            </div>
          </TabsContent>

          {/* Tab: Ubicaciones GPS */}
          <TabsContent value="locations" className="space-y-4">
            <div className="bg-white p-12 rounded-lg border">
              <div className="text-center">
                <MapPin className="h-16 w-16 mx-auto text-muted-foreground mb-4" />
                <h3 className="text-xl font-semibold mb-2">Gestión de Ubicaciones GPS</h3>
                <p className="text-muted-foreground mb-4">
                  Configura las ubicaciones GPS para validación de fichajes
                </p>
                <Button onClick={() => navigate('/admin/locations')} size="lg" className="text-black">
                  Gestionar Ubicaciones
                </Button>
              </div>
            </div>
          </TabsContent>
        </Tabs>
      </div>

      {/* Modals */}
      <TaskForm
        open={isTaskFormOpen}
        onClose={() => {
          setIsTaskFormOpen(false)
          setSelectedTask(null)
        }}
        onSubmit={handleTaskSubmit}
        task={selectedTask}
        employees={employees}
      />

      <AlertDialog open={!!taskToDelete} onOpenChange={() => setTaskToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Estás seguro?</AlertDialogTitle>
            <AlertDialogDescription>
              Esta acción no se puede deshacer. Se eliminará permanentemente la tarea{' '}
              <strong>{taskToDelete?.title}</strong> y todos sus registros asociados.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDeleteTask} className="bg-red-600 hover:bg-red-700">
              Eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Layout>
  )
}