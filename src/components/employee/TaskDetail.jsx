import { useState, useEffect } from 'react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Calendar, Users, Clock, MapPin, AlertCircle, Info } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { supabase } from '@/lib/supabase'

export default function TaskDetail({ task, open, onClose }) {
  const [checkins, setCheckins] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (task?.id && open) {
      fetchCheckins()
    }
  }, [task?.id, open])

  const fetchCheckins = async () => {
    if (!task?.id) return

    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('checkins')
        .select(`
          *,
          users (
            full_name,
            email
          )
        `)
        .eq('task_id', task.id)
        .order('checkin_time', { ascending: false })

      if (error) throw error

      setCheckins(data || [])
    } catch (error) {
      console.error('Error fetching checkins:', error)
      setCheckins([])
    } finally {
      setLoading(false)
    }
  }

  if (!task) return null

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

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <DialogTitle className="text-2xl text-gray-900">{task.title}</DialogTitle>
              <DialogDescription className="mt-2">
                {task.description || 'Sin descripción'}
              </DialogDescription>
            </div>
            {getStatusBadge(task.status)}
          </div>
        </DialogHeader>

        <div className="space-y-6">
          {/* Información General */}
          <Card>
            <CardContent className="pt-6 space-y-4">
              <h3 className="font-semibold text-gray-900 flex items-center gap-2">
                <Info className="h-5 w-5" />
                Información de la Tarea
              </h3>

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

                {task.checkin_location && (
                  <div className="flex items-center gap-3">
                    <MapPin className="h-5 w-5 text-gray-500" />
                    <div>
                      <p className="text-xs text-gray-500">Ubicación de Fichaje</p>
                      <p className="text-sm font-medium text-gray-900">{task.checkin_location}</p>
                    </div>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Incidencia */}
          {task.incident_description && (
            <Alert className="bg-red-50 border-red-200">
              <AlertCircle className="h-4 w-4 text-red-600" />
              <AlertDescription className="text-red-800">
                <strong>Incidencia Reportada:</strong>
                <p className="mt-1">{task.incident_description}</p>
                {task.incident_image && (
                  <img
                    src={task.incident_image}
                    alt="Incidencia"
                    className="mt-2 rounded border max-w-xs"
                  />
                )}
              </AlertDescription>
            </Alert>
          )}

          {/* Historial de Fichajes */}
          <Card>
            <CardContent className="pt-6">
              <h3 className="font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <Clock className="h-5 w-5" />
                Historial de Fichajes
              </h3>

              {loading ? (
                <div className="text-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto"></div>
                  <p className="mt-2 text-sm text-gray-600">Cargando fichajes...</p>
                </div>
              ) : checkins.length === 0 ? (
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
                            {checkin.latitude && checkin.longitude && (
                              <p className="text-xs text-gray-500 font-mono">
                                {checkin.latitude.toFixed(6)}, {checkin.longitude.toFixed(6)}
                              </p>
                            )}
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
      </DialogContent>
    </Dialog>
  )
}