import { useState, useEffect, useMemo } from 'react'
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
import { Button } from '@/components/ui/button'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { 
  Calendar, 
  Users, 
  Clock, 
  MapPin, 
  Info, 
  ExternalLink,
  TrendingUp,
  CheckCircle2,
  Activity,
  AlertCircle,
  Target,
  Timer,
  BarChart3,
  ArrowLeft,
  X
} from 'lucide-react'
import { format, differenceInMinutes, isBefore } from 'date-fns'
import { es } from 'date-fns/locale'
import { supabase } from '@/lib/supabase'
import { useNavigate } from 'react-router-dom'

export default function TaskDetail({ task, open, onClose }) {
  const [checkins, setCheckins] = useState([])
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()

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

  // Cálculo de métricas de progreso
  const taskMetrics = useMemo(() => {
    if (!task) return null

    const now = new Date()
    const totalCheckins = checkins.length
    const completedCheckins = checkins.filter(c => c.checkout_time).length
    const activeCheckins = checkins.filter(c => !c.checkout_time).length

    // Calcular tiempo total trabajado
    let totalWorkedMinutes = 0
    checkins.forEach(checkin => {
      if (checkin.checkout_time) {
        const start = new Date(checkin.checkin_time)
        const end = new Date(checkin.checkout_time)
        totalWorkedMinutes += differenceInMinutes(end, start)
      }
    })

    // Estado de la fecha programada
    let scheduleStatus = 'on-time'
    let scheduleDaysRemaining = 0
    if (task.schedule_date) {
      const scheduleDate = new Date(task.schedule_date)
      scheduleDaysRemaining = Math.ceil((scheduleDate - now) / (1000 * 60 * 60 * 24))
      
      if (isBefore(scheduleDate, now) && task.status !== 'completed') {
        scheduleStatus = 'overdue'
      } else if (scheduleDaysRemaining <= 2 && scheduleDaysRemaining >= 0) {
        scheduleStatus = 'urgent'
      }
    }

    // Progreso visual (basado en estado)
    let progress = 0
    if (task.status === 'pending') progress = 0
    else if (task.status === 'in_progress') progress = 50
    else if (task.status === 'completed') progress = 100

    return {
      totalCheckins,
      completedCheckins,
      activeCheckins,
      totalWorkedMinutes,
      totalWorkedHours: Math.floor(totalWorkedMinutes / 60),
      remainingMinutes: totalWorkedMinutes % 60,
      scheduleStatus,
      scheduleDaysRemaining,
      progress
    }
  }, [task, checkins])

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
      daily: { icon: '🔄', label: 'Diaria', bg: 'bg-purple-100', text: 'text-purple-800', border: 'border-purple-200' },
      weekly: { icon: '📅', label: 'Semanal', bg: 'bg-blue-100', text: 'text-blue-800', border: 'border-blue-200' },
      monthly: { icon: '📆', label: 'Mensual', bg: 'bg-indigo-100', text: 'text-indigo-800', border: 'border-indigo-200' },
      custom_date: { icon: '📅', label: 'Fecha Específica', bg: 'bg-pink-100', text: 'text-pink-800', border: 'border-pink-200' }
    }
    const config = types[type] || types.custom_date
    
    return (
      <Badge variant="outline" className={`${config.bg} ${config.text} ${config.border} border text-xs font-medium`}>
        {config.icon} {config.label}
      </Badge>
    )
  }

  const getProgressColor = () => {
    if (taskMetrics?.progress === 100) return 'from-green-500 to-emerald-500'
    if (taskMetrics?.progress >= 50) return 'from-blue-500 to-cyan-500'
    return 'from-amber-500 to-orange-500'
  }

  const getScheduleStatusBadge = () => {
    if (!taskMetrics) return null

    const { scheduleStatus, scheduleDaysRemaining } = taskMetrics

    if (scheduleStatus === 'overdue') {
      return (
        <Badge variant="outline" className="bg-red-100 text-red-800 border-red-200 border">
          <AlertCircle className="h-3 w-3 mr-1" />
          Vencida
        </Badge>
      )
    }

    if (scheduleStatus === 'urgent') {
      return (
        <Badge variant="outline" className="bg-orange-100 text-orange-800 border-orange-200 border">
          <Timer className="h-3 w-3 mr-1" />
          {scheduleDaysRemaining === 0 ? 'Hoy' : `${scheduleDaysRemaining} días`}
        </Badge>
      )
    }

    if (scheduleDaysRemaining > 0) {
      return (
        <Badge variant="outline" className="bg-green-100 text-green-800 border-green-200 border">
          <Target className="h-3 w-3 mr-1" />
          {scheduleDaysRemaining} {scheduleDaysRemaining === 1 ? 'día' : 'días'}
        </Badge>
      )
    }

    return null
  }

  const handleGoToFullDetail = () => {
    onClose()
    navigate(`/employee/task/${task.id}/work`)
  }

  if (!task) return null

  const statusBadge = getStatusBadge(task.status)

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        {/* Header con navegación */}
        <DialogHeader>
          <div className="flex items-start justify-between gap-4 mb-4">
            <Button
              variant="ghost"
              size="icon"
              onClick={onClose}
              className="shrink-0 hover:bg-gray-100"
            >
              <ArrowLeft className="h-5 w-5" />
            </Button>
            
            <div className="flex-1">
              <DialogTitle className="text-2xl font-bold text-gray-900 mb-3">
                {task.title}
              </DialogTitle>
              
              {/* Badges de estado y tipo */}
              <div className="flex items-center gap-2 flex-wrap mb-3">
                <Badge 
                  variant="outline" 
                  className={`${statusBadge.bg} ${statusBadge.text} ${statusBadge.border} border font-medium`}
                >
                  {statusBadge.label}
                </Badge>
                {task.schedule_type && getScheduleTypeBadge(task.schedule_type)}
                {getScheduleStatusBadge()}
              </div>
              
              <DialogDescription className="text-base text-gray-600">
                {task.description || 'Sin descripción'}
              </DialogDescription>
            </div>

            <Button
              variant="ghost"
              size="icon"
              onClick={onClose}
              className="shrink-0 hover:bg-gray-100"
            >
              <X className="h-5 w-5" />
            </Button>
          </div>
        </DialogHeader>

        <div className="space-y-6">
          {/* Barra de Progreso */}
          <div className="space-y-3 p-4 bg-gradient-to-r from-gray-50 to-gray-100 rounded-xl border-2 border-gray-200">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <TrendingUp className="h-5 w-5 text-blue-600" />
                <span className="text-sm font-semibold text-gray-700">Progreso de la Tarea</span>
              </div>
              <span className="text-2xl font-bold text-blue-600">{taskMetrics?.progress}%</span>
            </div>
            <div className="relative h-3 bg-gray-200 rounded-full overflow-hidden">
              <div 
                className={`absolute top-0 left-0 h-full bg-gradient-to-r ${getProgressColor()} transition-all duration-500 rounded-full`}
                style={{ width: `${taskMetrics?.progress}%` }}
              >
                <div className="absolute inset-0 bg-white/20 animate-pulse"></div>
              </div>
            </div>
          </div>

          {/* Métricas de Rendimiento */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <Card className="border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-blue-100 hover:shadow-md transition-shadow">
              <CardContent className="pt-5 pb-4">
                <div className="text-center">
                  <div className="mx-auto w-12 h-12 bg-blue-500 rounded-full flex items-center justify-center mb-2 shadow-sm">
                    <BarChart3 className="h-6 w-6 text-white" />
                  </div>
                  <p className="text-2xl font-bold text-blue-900">{taskMetrics?.totalCheckins || 0}</p>
                  <p className="text-xs text-blue-700 font-medium mt-1">Total Fichajes</p>
                </div>
              </CardContent>
            </Card>

            <Card className="border-2 border-green-200 bg-gradient-to-br from-green-50 to-green-100 hover:shadow-md transition-shadow">
              <CardContent className="pt-5 pb-4">
                <div className="text-center">
                  <div className="mx-auto w-12 h-12 bg-green-500 rounded-full flex items-center justify-center mb-2 shadow-sm">
                    <CheckCircle2 className="h-6 w-6 text-white" />
                  </div>
                  <p className="text-2xl font-bold text-green-900">{taskMetrics?.completedCheckins || 0}</p>
                  <p className="text-xs text-green-700 font-medium mt-1">Completados</p>
                </div>
              </CardContent>
            </Card>

            <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-purple-100 hover:shadow-md transition-shadow">
              <CardContent className="pt-5 pb-4">
                <div className="text-center">
                  <div className="mx-auto w-12 h-12 bg-purple-500 rounded-full flex items-center justify-center mb-2 shadow-sm">
                    <Activity className="h-6 w-6 text-white" />
                  </div>
                  <p className="text-2xl font-bold text-purple-900">{taskMetrics?.activeCheckins || 0}</p>
                  <p className="text-xs text-purple-700 font-medium mt-1">En Curso</p>
                </div>
              </CardContent>
            </Card>

            <Card className="border-2 border-orange-200 bg-gradient-to-br from-orange-50 to-orange-100 hover:shadow-md transition-shadow">
              <CardContent className="pt-5 pb-4">
                <div className="text-center">
                  <div className="mx-auto w-12 h-12 bg-orange-500 rounded-full flex items-center justify-center mb-2 shadow-sm">
                    <Clock className="h-6 w-6 text-white" />
                  </div>
                  <p className="text-2xl font-bold text-orange-900">
                    {taskMetrics?.totalWorkedHours || 0}h
                  </p>
                  <p className="text-xs text-orange-700 font-medium mt-1">Tiempo Total</p>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Información General */}
          <Card className="border-2 shadow-sm">
            <CardContent className="pt-6 space-y-4">
              <h3 className="font-semibold text-gray-900 flex items-center gap-2 text-lg">
                <Info className="h-5 w-5 text-blue-600" />
                Información General
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {task.schedule_date && (
                  <div className="flex items-start gap-3 p-4 bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl border border-gray-200">
                    <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center shrink-0">
                      <Calendar className="h-5 w-5 text-blue-600" />
                    </div>
                    <div className="flex-1">
                      <p className="text-xs text-gray-600 font-semibold mb-1">Fecha Programada</p>
                      <p className="text-sm font-bold text-gray-900">
                        {format(new Date(task.schedule_date), 'PPP', { locale: es })}
                      </p>
                    </div>
                  </div>
                )}

                <div className="flex items-start gap-3 p-4 bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl border border-gray-200">
                  <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center shrink-0">
                    <Users className="h-5 w-5 text-purple-600" />
                  </div>
                  <div className="flex-1">
                    <p className="text-xs text-gray-600 font-semibold mb-1">Asignada a</p>
                    <p className="text-sm font-bold text-gray-900">{task.assigned_names}</p>
                  </div>
                </div>

                {task.last_checkin && (
                  <div className="flex items-start gap-3 p-4 bg-gradient-to-br from-green-50 to-green-100 rounded-xl border border-green-200">
                    <div className="w-10 h-10 bg-green-200 rounded-lg flex items-center justify-center shrink-0">
                      <Clock className="h-5 w-5 text-green-700" />
                    </div>
                    <div className="flex-1">
                      <p className="text-xs text-green-700 font-semibold mb-1">Último Fichaje</p>
                      <p className="text-sm font-bold text-green-900">
                        {format(new Date(task.last_checkin), 'PPp', { locale: es })}
                      </p>
                    </div>
                  </div>
                )}

                {task.expected_latitude && task.expected_longitude && (
                  <div className="flex items-start gap-3 p-4 bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl border border-blue-200">
                    <div className="w-10 h-10 bg-blue-200 rounded-lg flex items-center justify-center shrink-0">
                      <MapPin className="h-5 w-5 text-blue-700" />
                    </div>
                    <div className="flex-1">
                      <p className="text-xs text-blue-700 font-semibold mb-1">GPS Requerido</p>
                      <p className="text-sm font-bold text-blue-900">
                        Radio: {task.location_radius || 50}m
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Incidencia */}
          {task.incident_description && (
            <Alert className="bg-gradient-to-br from-red-50 to-red-100 border-2 border-red-300 shadow-sm">
              <AlertCircle className="h-5 w-5 text-red-600" />
              <AlertDescription className="text-red-900">
                <strong className="block mb-2 text-base">⚠️ Incidencia Reportada</strong>
                <p className="text-sm">{task.incident_description}</p>
                {task.incident_image && (
                  <img
                    src={task.incident_image}
                    alt="Incidencia"
                    className="mt-3 rounded-lg border-2 border-red-300 max-w-md shadow-md"
                  />
                )}
              </AlertDescription>
            </Alert>
          )}

          {/* Últimos Fichajes */}
          <Card className="border-2 shadow-sm">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-semibold text-gray-900 flex items-center gap-2 text-lg">
                  <TrendingUp className="h-5 w-5 text-purple-600" />
                  Historial de Fichajes
                </h3>
                {checkins.length > 0 && (
                  <Badge variant="outline" className="bg-purple-100 text-purple-800 border-purple-200 border font-medium">
                    {checkins.length} {checkins.length === 1 ? 'registro' : 'registros'}
                  </Badge>
                )}
              </div>

              {loading ? (
                <div className="text-center py-12">
                  <div className="animate-spin rounded-full h-12 w-12 border-4 border-blue-500 border-t-transparent mx-auto"></div>
                  <p className="mt-4 text-sm text-gray-600 font-medium">Cargando fichajes...</p>
                </div>
              ) : checkins.length === 0 ? (
                <div className="text-center py-12 bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl border-2 border-dashed border-gray-300">
                  <div className="mx-auto w-16 h-16 bg-gray-200 rounded-full flex items-center justify-center mb-3">
                    <Clock className="h-8 w-8 text-gray-400" />
                  </div>
                  <p className="text-gray-600 font-medium">No hay fichajes registrados</p>
                  <p className="text-sm text-gray-500 mt-1">Los fichajes aparecerán aquí</p>
                </div>
              ) : (
                <div className="rounded-xl border-2 overflow-hidden shadow-sm">
                  <Table>
                    <TableHeader>
                      <TableRow className="bg-gradient-to-r from-gray-100 to-gray-50">
                        <TableHead className="font-bold text-gray-700">Fecha y Hora</TableHead>
                        <TableHead className="font-bold text-gray-700">Empleado</TableHead>
                        <TableHead className="font-bold text-gray-700">Duración</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {checkins.slice(0, 5).map((checkin) => {
                        const duration = checkin.checkout_time 
                          ? differenceInMinutes(new Date(checkin.checkout_time), new Date(checkin.checkin_time))
                          : null

                        return (
                          <TableRow key={checkin.id} className="hover:bg-gray-50">
                            <TableCell className="font-medium">
                              <div className="flex items-center gap-2">
                                <Clock className="h-4 w-4 text-gray-400" />
                                {format(new Date(checkin.checkin_time), 'PPp', { locale: es })}
                              </div>
                            </TableCell>
                            <TableCell>
                              <div>
                                <p className="font-semibold text-gray-900">
                                  {checkin.users?.full_name || 'Desconocido'}
                                </p>
                                <p className="text-xs text-gray-500">{checkin.users?.email}</p>
                              </div>
                            </TableCell>
                            <TableCell>
                              {duration ? (
                                <Badge variant="outline" className="bg-green-100 text-green-800 border-green-200 border font-medium">
                                  {Math.floor(duration / 60)}h {duration % 60}m
                                </Badge>
                              ) : (
                                <Badge variant="outline" className="bg-blue-100 text-blue-800 border-blue-200 border font-medium">
                                  <Activity className="h-3 w-3 mr-1" />
                                  En curso
                                </Badge>
                              )}
                            </TableCell>
                          </TableRow>
                        )
                      })}
                    </TableBody>
                  </Table>
                </div>
              )}

              {checkins.length > 5 && (
                <p className="text-center text-sm text-gray-500 mt-4">
                  Mostrando los últimos 5 fichajes de {checkins.length} totales
                </p>
              )}
            </CardContent>
          </Card>

          {/* CTA para ir a la página completa */}
          <div className="sticky bottom-0 pt-4 pb-2 bg-white/95 backdrop-blur-sm border-t-2 border-gray-200">
            <Button
              onClick={handleGoToFullDetail}
              className="w-full bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white font-semibold shadow-lg hover:shadow-xl transition-all group"
              size="lg"
            >
              <span className="flex items-center justify-center gap-2">
                Acceder a la Tarea Completa
                <ExternalLink className="h-5 w-5 group-hover:translate-x-1 transition-transform" />
              </span>
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}