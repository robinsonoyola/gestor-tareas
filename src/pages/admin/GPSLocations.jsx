import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import Layout from '@/components/layout/Layout'
import { useTasks } from '@/hooks/useTasks'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
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
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Badge } from '@/components/ui/badge'
import { ArrowLeft, MapPin, Edit, Trash2, Info, AlertTriangle } from 'lucide-react'
import { supabase } from '@/lib/supabase'

export default function GPSLocations() {
  const navigate = useNavigate()
  const { tasks, loading: tasksLoading, fetchTasks } = useTasks()
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [selectedTask, setSelectedTask] = useState(null)
  const [taskToDelete, setTaskToDelete] = useState(null)
  const [formData, setFormData] = useState({
    latitude: '',
    longitude: '',
    radius: 50
  })

  const handleEdit = (task) => {
    setSelectedTask(task)
    setFormData({
      latitude: task.expected_latitude || '',
      longitude: task.expected_longitude || '',
      radius: task.location_radius || 50
    })
    setIsDialogOpen(true)
  }

  const handleDelete = (task) => {
    setTaskToDelete(task)
  }

  const confirmDelete = async () => {
    if (!taskToDelete) return

    try {
      const { error } = await supabase
        .from('tasks')
        .update({
          expected_latitude: null,
          expected_longitude: null,
          location_radius: 50
        })
        .eq('id', taskToDelete.id)

      if (error) throw error

      toast.success('Ubicación GPS eliminada correctamente')
      await fetchTasks()
    } catch (error) {
      console.error('Error al eliminar ubicación:', error)
      toast.error('No se pudo eliminar la ubicación GPS')
    }

    setTaskToDelete(null)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()

    if (!selectedTask) return

    const lat = parseFloat(formData.latitude)
    const lng = parseFloat(formData.longitude)
    const radius = parseInt(formData.radius)

    if (isNaN(lat) || lat < -90 || lat > 90) {
      toast.error('Latitud inválida (debe estar entre -90 y 90)')
      return
    }

    if (isNaN(lng) || lng < -180 || lng > 180) {
      toast.error('Longitud inválida (debe estar entre -180 y 180)')
      return
    }

    if (isNaN(radius) || radius < 1) {
      toast.error('Radio inválido (debe ser mayor a 0)')
      return
    }

    try {
      const { error } = await supabase
        .from('tasks')
        .update({
          expected_latitude: lat,
          expected_longitude: lng,
          location_radius: radius
        })
        .eq('id', selectedTask.id)

      if (error) throw error

      toast.success('Ubicación GPS configurada correctamente')
      setIsDialogOpen(false)
      setSelectedTask(null)
      await fetchTasks()
    } catch (error) {
      console.error('Error al guardar ubicación:', error)
      toast.error('No se pudo guardar la ubicación GPS')
    }
  }

  const getCurrentLocation = () => {
    if (!navigator.geolocation) {
      toast.error('Tu navegador no soporta geolocalización')
      return
    }

    toast.info('Obteniendo tu ubicación actual...')

    navigator.geolocation.getCurrentPosition(
      (position) => {
        setFormData(prev => ({
          ...prev,
          latitude: position.coords.latitude.toFixed(6),
          longitude: position.coords.longitude.toFixed(6)
        }))
        toast.success('Ubicación obtenida correctamente')
      },
      (error) => {
        console.error('Error al obtener ubicación:', error)
        toast.error('No se pudo obtener la ubicación actual')
      }
    )
  }

  const openInGoogleMaps = (lat, lng) => {
    window.open(`https://www.google.com/maps?q=${lat},${lng}`, '_blank')
  }

  if (tasksLoading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
            <p className="mt-4 text-gray-600">Cargando tareas...</p>
          </div>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">📍 Configurar Ubicaciones de Tareas</h1>
            <p className="text-gray-600 mt-1">
              Configura las coordenadas GPS exactas donde deben realizarse las tareas
            </p>
          </div>
          <Button
            variant="outline"
            onClick={() => navigate('/admin')}
            className="bg-gray-600 text-white hover:bg-gray-700 hover:text-white"
          >
            <ArrowLeft className="mr-2 h-4 w-4" />
            Volver al Panel
          </Button>
        </div>

        <Alert className="bg-blue-50 border-blue-200">
          <Info className="h-4 w-4 text-blue-600" />
          <AlertDescription className="text-blue-800">
            <strong>💡 ¿Cómo funciona la validación de ubicación?</strong>
            <ul className="mt-2 space-y-1 list-disc list-inside text-sm">
              <li>Configura las coordenadas GPS exactas donde debe realizarse cada tarea</li>
              <li>Define un radio de tolerancia (recomendado: 30-50 metros para interiores)</li>
              <li>Los empleados solo podrán fichar si están físicamente en el lugar</li>
              <li>Evita que tomen foto del QR y fichen desde otro lugar</li>
            </ul>
          </AlertDescription>
        </Alert>

        <Alert className="bg-teal-50 border-teal-200">
          <MapPin className="h-4 w-4 text-teal-600" />
          <AlertDescription className="text-teal-800">
            <strong>📌 Para obtener coordenadas:</strong>
            <ol className="mt-2 space-y-1 list-decimal list-inside text-sm">
              <li>Abre Google Maps en tu computadora</li>
              <li>Busca el lugar exacto (habitación, área, etc.)</li>
              <li>Haz clic derecho sobre el punto exacto</li>
              <li>Selecciona "Copiar coordenadas" del menú</li>
              <li>Pega aquí las coordenadas (formato: 40.416775, -3.703790)</li>
            </ol>
          </AlertDescription>
        </Alert>

        <Alert className="bg-yellow-50 border-yellow-200">
          <AlertTriangle className="h-4 w-4 text-yellow-600" />
          <AlertDescription className="text-yellow-800">
            <strong>⚠️ Importante sobre la precisión GPS:</strong>
            <p className="text-sm mt-1">
              El GPS en móviles tiene una precisión de ±5-15 metros. En interiores puede llegar a ±20-50 metros.
              <br />
              <strong className="text-red-700">Radios muy pequeños pueden causar rechazos falsos.</strong>
            </p>
          </AlertDescription>
        </Alert>

        <Card>
          <CardHeader className="bg-gradient-to-r from-purple-500 to-purple-600 text-white">
            <CardTitle className="flex items-center gap-2">
              <MapPin className="h-5 w-5" />
              Ubicaciones GPS de las Tareas
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-[80px]">ID</TableHead>
                    <TableHead>Tarea</TableHead>
                    <TableHead>Asignada a</TableHead>
                    <TableHead>Ubicación GPS</TableHead>
                    <TableHead className="text-center">Radio (m)</TableHead>
                    <TableHead className="text-right">Acciones</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {tasks.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} className="text-center py-8 text-gray-500">
                        ❌ Error al cargar tareas
                      </TableCell>
                    </TableRow>
                  ) : (
                    tasks.map((task) => (
                      <TableRow key={task.id}>
                        <TableCell className="font-mono text-xs text-gray-500">
                          {task.id.slice(0, 8)}...
                        </TableCell>
                        <TableCell className="font-medium text-gray-900">{task.title}</TableCell>
                        <TableCell className="text-sm text-gray-600">{task.assigned_names}</TableCell>
                        <TableCell>
                          {task.expected_latitude && task.expected_longitude ? (
                            <div className="space-y-1">
                              <button
                                onClick={() => openInGoogleMaps(task.expected_latitude, task.expected_longitude)}
                                className="text-xs font-mono text-blue-600 hover:underline"
                              >
                                {task.expected_latitude.toFixed(6)}, {task.expected_longitude.toFixed(6)}
                              </button>
                              <Badge className="bg-green-100 text-green-800 text-xs ml-2">
                                ✅ Configurado
                              </Badge>
                            </div>
                          ) : (
                            <Badge variant="outline" className="bg-gray-100 text-gray-600">
                              ❌ Sin configurar
                            </Badge>
                          )}
                        </TableCell>
                        <TableCell className="text-center">
                          {task.location_radius || 50}
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex justify-end gap-2">
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleEdit(task)}
                              className="bg-blue-50 hover:bg-blue-100 text-blue-700 border-blue-200"
                            >
                              <Edit className="h-4 w-4 mr-1" />
                              Editar
                            </Button>
                            {task.expected_latitude && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => handleDelete(task)}
                                className="bg-red-50 hover:bg-red-100 text-red-700 border-red-200"
                              >
                                <Trash2 className="h-4 w-4 mr-1" />
                                Eliminar
                              </Button>
                            )}
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>
      </div>

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle className="text-xl">📍 Configurar Ubicación GPS</DialogTitle>
            <DialogDescription>
              Tarea: <strong>{selectedTask?.title}</strong>
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="latitude" className="text-gray-900 font-semibold">
                  Latitud *
                </Label>
                <Input
                  id="latitude"
                  type="number"
                  step="0.000001"
                  value={formData.latitude}
                  onChange={(e) => setFormData(prev => ({ ...prev, latitude: e.target.value }))}
                  placeholder="40.416775"
                  required
                  className="border-gray-300"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="longitude" className="text-gray-900 font-semibold">
                  Longitud *
                </Label>
                <Input
                  id="longitude"
                  type="number"
                  step="0.000001"
                  value={formData.longitude}
                  onChange={(e) => setFormData(prev => ({ ...prev, longitude: e.target.value }))}
                  placeholder="-3.703790"
                  required
                  className="border-gray-300"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="radius" className="text-gray-900 font-semibold">
                Radio de tolerancia (metros) *
              </Label>
              <Input
                id="radius"
                type="number"
                min="1"
                value={formData.radius}
                onChange={(e) => setFormData(prev => ({ ...prev, radius: e.target.value }))}
                required
                className="border-gray-300"
              />
              <p className="text-xs text-gray-500">
                Recomendado: 30-50 metros para interiores, 10-20 metros para exteriores
              </p>
            </div>

            <Button
              type="button"
              variant="outline"
              onClick={getCurrentLocation}
              className="w-full bg-green-50 hover:bg-green-100 text-green-700 border-green-200"
            >
              <MapPin className="mr-2 h-4 w-4" />
              Usar mi ubicación actual
            </Button>

            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => setIsDialogOpen(false)}
                className="bg-gray-100 text-gray-900 hover:bg-gray-200"
              >
                Cancelar
              </Button>
              <Button type="submit" className="bg-blue-500 hover:bg-blue-600 text-white">
                💾 Guardar Ubicación
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!taskToDelete} onOpenChange={() => setTaskToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Eliminar ubicación GPS?</AlertDialogTitle>
            <AlertDialogDescription>
              Se eliminará la configuración GPS de la tarea{' '}
              <strong>{taskToDelete?.title}</strong>.
              <br />
              Los empleados podrán fichar desde cualquier ubicación.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={confirmDelete}
              className="bg-red-600 hover:bg-red-700 text-white"
            >
              Eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Layout>
  )
}