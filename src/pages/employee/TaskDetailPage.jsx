import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { useAuth } from '@/hooks/useAuth'
import Layout from '@/components/layout/Layout'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Badge } from '@/components/ui/badge'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import {
  ArrowLeft,
  Calendar,
  Users,
  Clock,
  MapPin,
  AlertCircle,
  CheckCircle,
  Info
} from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { supabase } from '@/lib/supabase'

export default function TaskDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { userData } = useAuth()

  const [task, setTask] = useState(null)
  const [checkins, setCheckins] = useState([])
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)

  // Formulario de fichaje/incidencia
  const [incidentForm, setIncidentForm] = useState({
    responsible: '',
    imageUrl: ''
  })

  useEffect(() => {
    if (id) {
      fetchTaskDetail()
      fetchCheckins()
    }
  }, [id])

  const fetchTaskDetail = async () => {
    try {
      setLoading(true)

      const { data, error } = await supabase
        .from('tasks')
        .select(`
          *,
          task_assignments!inner (
            user_id,
            users (
              id,
              full_name,
              email
            )
          )
        `)
        .eq('id', id)
        .single()

      if (error) throw error

      // Procesar datos de usuarios asignados
      const assignedUsers = []
      const tasksWithUsers = await supabase
        .from('task_assignments')
        .select(`
          users (
            id,
            full_name,
            email
          )
        `)
        .eq('task_id', id)

      if (tasksWithUsers.data) {
        tasksWithUsers.data.forEach(item => {
          if (item.users) {
            assignedUsers.push(item.users)
          }
        })
      }

      setTask({
        ...data,
        assigned_users: assignedUsers,
        assigned_names: assignedUsers.map(u => u.full_name).join(', ') || 'Sin asignar'
      })

    } catch (error) {
      console.error('Error fetching task:', error)
      toast.error('Error al cargar la tarea')
    } finally {
      setLoading(false)
    }
  }

  const fetchCheckins = async () => {
    try {
      const { data, error } = await supabase
        .from('checkins')
        .select(`
          *,
          users (
            full_name,
            email
          )
        `)
        .eq('task_id', id)
        .order('checkin_time', { ascending: false })

      if (error) throw error
      setCheckins(data || [])
    } catch (error) {
      console.error('Error fetching checkins:', error)
    }
  }

  const handleRegisterCheckin = async (e) => {
    e.preventDefault()
    setSubmitting(true)

    try {
      // Obtener ubicación GPS
      let latitude = null
      let longitude = null
      let locationText = 'Sin ubicación'

      if (navigator.geolocation) {
        try {
          const position = await new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(resolve, reject, {
              timeout: 10000,
              enableHighAccuracy: true
            })
          })

          latitude = position.coords.latitude
          longitude = position.coords.longitude
          locationText = `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`

          // Validar si la tarea tiene ubicación GPS esperada
          if (task.expected_latitude && task.expected_longitude) {
            const distance = calculateDistance(
              latitude,
              longitude,
              task.expected_latitude,
              task.expected_longitude
            )

            const radius = task.location_radius || 50

            if (distance > radius) {
              const confirmOutside = window.confirm(
                `⚠️ Estás a ${distance.toFixed(0)} metros de la ubicación esperada.\n` +
                `Límite permitido: ${radius} metros.\n\n` +
                `¿Deseas registrar el fichaje de todos modos?`
              )

              if (!confirmOutside) {
                toast.error('Fichaje cancelado. Debes estar en la ubicación correcta.')
                setSubmitting(false)
                return
              }
            }
          }
        } catch (geoError) {
          console.error('Error getting location:', geoError)
          toast.warning('No se pudo obtener la ubicación GPS')
        }
      }

      // Registrar fichaje
      const { error: checkinError } = await supabase
        .from('checkins')
        .insert([{
          task_id: id,
          user_id: userData.id,
          location: locationText,
          latitude,
          longitude,
          qr_code: 'Manual'
        }])

      if (checkinError) throw checkinError

      // Actualizar tarea con última fecha de fichaje
      await supabase
        .from('tasks')
        .update({
          last_checkin: new Date().toISOString(),
          checkin_latitude: latitude,
          checkin_longitude: longitude,
          checkin_location: locationText
        })
        .eq('id', id)

      // Si hay información de incidencia, actualizar tarea
      if (incidentForm.responsible || incidentForm.imageUrl) {
        await supabase
          .from('tasks')
          .update({
            incident_description: incidentForm.responsible,
            incident_image: incidentForm.imageUrl
          })
          .eq('id', id)
      }

      toast.success('✅ Fichaje registrado correctamente')

      // Limpiar formulario y recargar datos
      setIncidentForm({ responsible: '', imageUrl: '' })
      await fetchTaskDetail()
      await fetchCheckins()

    } catch (error) {
      console.error('Error registering checkin:', error)
      toast.error('Error al registrar el fichaje')
    } finally {
      setSubmitting(false)
    }
  }

  // Calcular distancia entre dos puntos GPS (fórmula de Haversine)
  const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371e3 // Radio de la Tierra en metros
    const φ1 = (lat1 * Math.PI) / 180
    const φ2 = (lat2 * Math.PI) / 180
    const Δφ = ((lat2 - lat1) * Math.PI) / 180
    const Δλ = ((lon2 - lon1) * Math.PI) / 180

    const a =
      Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
      Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2)
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    return R * c // Distancia en metros
  }

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
            <p className="mt-4 text-gray-600">Cargando detalle de tarea...</p>
          </div>
        </div>
      </Layout>
    )
  }

  if (!task) {
    return (
      <Layout>
        <div className="text-center py-12">
          <Alert className="bg-red-50 border-red-200 max-w-2xl mx-auto">
            <AlertCircle className="h-4 w-4 text-red-600" />
            <AlertDescription className="text-red-800">
              <strong>Error:</strong> No se encontró la tarea. Verifica el ID en la URL.
            </AlertDescription>
          </Alert>
          <Button onClick={() => navigate('/employee')} className="mt-4">
            Volver a Mis Tareas
          </Button>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="space-y-6 max-w-6xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-3">
              <h1 className="text-3xl font-bold text-gray-900">📋 Detalle de Tarea</h1>
              {getStatusBadge(task.status)}
            </div>
            <p className="text-gray-600 mt-1">{task.title}</p>
          </div>
          <Button
            variant="outline"
            onClick={() => navigate('/employee')}
            className="bg-gray-600 text-white hover:bg-gray-700 hover:text-white"
          >
            <ArrowLeft className="mr-2 h-4 w-4" />
            Volver a Mis Tareas
          </Button>
        </div>

        {/* Información de la Tarea */}
        <Card>
          <CardHeader className="bg-gradient-to-r from-blue-500 to-blue-600 text-white">
            <CardTitle className="flex items-center gap-2">
              <Info className="h-5 w-5" />
              Información de la Tarea
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-6 space-y-4">
            <div>
              <Label className="text-gray-700 font-semibold">Descripción:</Label>
              <p className="text-gray-900 mt-1">{task.description || 'Sin descripción'}</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {task.schedule_date && (
                <div className="flex items-center gap-3">
                  <Calendar className="h-5 w-5 text-gray-500" />
                  <div>
                    <p className="text-xs text-gray-500">Fecha Programada</p>
                    <p className="text-sm font-medium text-gray-900">
                      {format(new Date(task.schedule_date), 'PPP', { locale: es })}
                    </p>
                  </div>
                </div>
              )}

              <div className="flex items-center gap-3">
                <Users className="h-5 w-5 text-gray-500" />
                <div>
                  <p className="text-xs text-gray-500">Asignada a</p>
                  <p className="text-sm font-medium text-gray-900">{task.assigned_names}</p>
                </div>
              </div>

              {task.last_checkin && (
                <div className="flex items-center gap-3">
                  <Clock className="h-5 w-5 text-gray-500" />
                  <div>
                    <p className="text-xs text-gray-500">Último Fichaje</p>
                    <p className="text-sm font-medium text-gray-900">
                      {format(new Date(task.last_checkin), 'PPp', { locale: es })}
                    </p>
                  </div>
                </div>
              )}

              {task.expected_latitude && task.expected_longitude && (
                <div className="flex items-center gap-3">
                  <MapPin className="h-5 w-5 text-gray-500" />
                  <div>
                    <p className="text-xs text-gray-500">Ubicación GPS Requerida</p>
                    <p className="text-sm font-medium text-gray-900">
                      Radio: {task.location_radius || 50} metros
                    </p>
                  </div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Formulario de Fichaje */}
        <Card>
          <CardHeader className="bg-gradient-to-r from-green-500 to-green-600 text-white">
            <CardTitle className="flex items-center gap-2">
              <CheckCircle className="h-5 w-5" />
              Fichaje e Incidencias
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-6">
            <form onSubmit={handleRegisterCheckin} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="responsible" className="text-gray-900 font-semibold">
                  Responsable de la incidencia (opcional)
                </Label>
                <Input
                  id="responsible"
                  type="text"
                  value={incidentForm.responsible}
                  onChange={(e) => setIncidentForm(prev => ({ ...prev, responsible: e.target.value }))}
                  placeholder="Nombre de la persona que gestiona la incidencia"
                  className="border-gray-300"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="imageUrl" className="text-gray-900 font-semibold">
                  URL de la imagen de la incidencia (opcional)
                </Label>
                <Input
                  id="imageUrl"
                  type="url"
                  value={incidentForm.imageUrl}
                  onChange={(e) => setIncidentForm(prev => ({ ...prev, imageUrl: e.target.value }))}
                  placeholder="https://ejemplo.com/imagen.jpg"
                  className="border-gray-300"
                />
              </div>

              <Button
                type="submit"
                disabled={submitting}
                className="w-full bg-blue-500 hover:bg-blue-600 text-white"
                size="lg"
              >
                {submitting ? '⏳ Registrando...' : '✔️ Registrar Fichaje'}
              </Button>
            </form>
          </CardContent>
        </Card>

        {/* Historial de Fichajes */}
        <Card>
          <CardHeader className="bg-gradient-to-r from-purple-500 to-purple-600 text-white">
            <CardTitle className="flex items-center gap-2">
              <Clock className="h-5 w-5" />
              Historial de Fichajes
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-6">
            {checkins.length === 0 ? (
              <div className="text-center py-8">
                <p className="text-gray-500">📭 No hay fichajes registrados para esta tarea</p>
              </div>
            ) : (
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Fecha y Hora</TableHead>
                      <TableHead>Empleado</TableHead>
                      <TableHead>Ubicación</TableHead>
                      <TableHead>Código QR</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {checkins.map((checkin) => (
                      <TableRow key={checkin.id}>
                        <TableCell className="font-medium">
                          {format(new Date(checkin.checkin_time), 'PPp', { locale: es })}
                        </TableCell>
                        <TableCell>
                          <div>
                            <p className="font-medium text-gray-900">
                              {checkin.users?.full_name || 'Desconocido'}
                            </p>
                            <p className="text-xs text-gray-500">{checkin.users?.email}</p>
                          </div>
                        </TableCell>
                        <TableCell>
                          {checkin.location || 'Sin ubicación'}
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline" className="bg-blue-50 text-blue-700">
                            {checkin.qr_code || 'Manual'}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </Layout>
  )
}