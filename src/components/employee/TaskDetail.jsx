import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { formatDate, formatDateTime, getStatusBadge } from '@/lib/utils'
import { Calendar, Users, Clock, MapPin, AlertCircle } from 'lucide-react'

export default function TaskDetail({ task, open, onClose }) {
  const [checkins, setCheckins] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (open && task) {
      fetchCheckins()
    }
  }, [open, task])

  const fetchCheckins = async () => {
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
    } finally {
      setLoading(false)
    }
  }

  if (!task) return null

  const statusInfo = getStatusBadge(task.status)
  
  const getStatusVariant = (status) => {
    const variants = {
      pending: 'warning',
      in_progress: 'default',
      completed: 'success'
    }
    return variants[status] || 'default'
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl">📋 Detalle de Tarea</DialogTitle>
          <DialogDescription>
            Información completa de la tarea #{task.id.slice(0, 8)}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Información Principal */}
          <Card>
            <CardHeader>
              <div className="flex justify-between items-start">
                <CardTitle>{task.title}</CardTitle>
                <Badge variant={getStatusVariant(task.status)}>
                  {statusInfo.label}
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Descripción */}
              {task.description && (
                <div>
                  <h4 className="font-semibold mb-2">Descripción:</h4>
                  <p className="text-sm text-muted-foreground">{task.description}</p>
                </div>
              )}

              <Separator />

              {/* Detalles */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                <div className="flex items-start gap-2">
                  <Calendar className="h-4 w-4 mt-0.5 text-muted-foreground" />
                  <div>
                    <p className="font-medium">Fecha Programada</p>
                    <p className="text-muted-foreground">{formatDate(task.schedule_date)}</p>
                  </div>
                </div>

                <div className="flex items-start gap-2">
                  <Users className="h-4 w-4 mt-0.5 text-muted-foreground" />
                  <div>
                    <p className="font-medium">Asignada a</p>
                    <p className="text-muted-foreground">{task.assigned_names || 'Sin asignar'}</p>
                  </div>
                </div>

                <div className="flex items-start gap-2">
                  <Clock className="h-4 w-4 mt-0.5 text-muted-foreground" />
                  <div>
                    <p className="font-medium">Último Fichaje</p>
                    <p className="text-muted-foreground">
                      {task.last_checkin ? formatDateTime(task.last_checkin) : 'Sin fichaje registrado'}
                    </p>
                  </div>
                </div>

                {task.checkin_location && (
                  <div className="flex items-start gap-2">
                    <MapPin className="h-4 w-4 mt-0.5 text-muted-foreground" />
                    <div>
                      <p className="font-medium">Ubicación</p>
                      <p className="text-muted-foreground">{task.checkin_location}</p>
                    </div>
                  </div>
                )}
              </div>

              {/* Incidencia */}
              {task.incident_description && (
                <>
                  <Separator />
                  <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4 rounded">
                    <div className="flex items-start gap-2">
                      <AlertCircle className="h-5 w-5 text-yellow-600 mt-0.5" />
                      <div>
                        <h4 className="font-semibold text-yellow-800">Incidencia Reportada</h4>
                        <p className="text-sm text-yellow-700 mt-1">
                          {task.incident_description}
                        </p>
                      </div>
                    </div>
                  </div>
                </>
              )}
            </CardContent>
          </Card>

          {/* Historial de Fichajes */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">📊 Historial de Fichajes</CardTitle>
            </CardHeader>
            <CardContent>
              {loading ? (
                <p className="text-center text-muted-foreground py-4">Cargando historial...</p>
              ) : checkins.length === 0 ? (
                <div className="text-center py-8">
                  <div className="text-4xl mb-2">📭</div>
                  <p className="text-muted-foreground">No hay fichajes registrados para esta tarea</p>
                  <p className="text-sm text-muted-foreground mt-1">
                    Los fichajes aparecerán aquí cuando los empleados registren su trabajo
                  </p>
                </div>
              ) : (
                <div className="space-y-3">
                  {checkins.map((checkin) => (
                    <div 
                      key={checkin.id}
                      className="bg-gray-50 p-4 rounded-lg border-l-4 border-green-500"
                    >
                      <div className="flex justify-between items-start mb-2">
                        <p className="font-semibold">
                          📅 {formatDateTime(checkin.checkin_time)}
                        </p>
                      </div>
                      <div className="text-sm text-muted-foreground space-y-1">
                        <p>
                          👤 <strong>Usuario:</strong> {checkin.users?.full_name || 'Desconocido'}
                        </p>
                        <p>
                          📍 <strong>Ubicación:</strong> {checkin.location || 'No especificada'}
                        </p>
                        {checkin.qr_code && (
                          <p>
                            🔲 <strong>QR:</strong> {checkin.qr_code}
                          </p>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </DialogContent>
    </Dialog>
  )
}