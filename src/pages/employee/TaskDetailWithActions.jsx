import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import Layout from '@/components/layout/Layout'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Textarea } from '@/components/ui/textarea'
import { Alert, AlertDescription } from '@/components/ui/alert'
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
  Clock, 
  MapPin, 
  Users, 
  Calendar,
  CheckCircle,
  Info,
  Upload,
  Image as ImageIcon,
  Video,
  X,
  NfcIcon,
  ArrowLeft,
  Activity,
  Timer,
  Play,
  Square
} from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { useAuth } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase'

export default function TaskDetailWithActions() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { userData } = useAuth()
  
  const [task, setTask] = useState(null)
  const [checkins, setCheckins] = useState([])
  const [comments, setComments] = useState([])
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [activeCheckin, setActiveCheckin] = useState(null)
  const [fichajeTime, setFichajeTime] = useState(null)
  
  const [nfcSupported, setNfcSupported] = useState(false)
  const [isReadingNFC, setIsReadingNFC] = useState(false)
  const [checkinConfig, setCheckinConfig] = useState({
    nfc_enabled: false,
    qr_enabled: true,
    manual_enabled: true
  })
  
  const [commentForm, setCommentForm] = useState({
    comment: '',
    imageFile: null,
    videoFile: null
  })

  const [imagePreview, setImagePreview] = useState(null)
  const [videoPreview, setVideoPreview] = useState(null)
  const [uploadProgress, setUploadProgress] = useState(0)

  useEffect(() => {
    if (id) {
      fetchTaskDetails()
      fetchCheckins()
      fetchComments()
      checkActiveCheckin()
    }
  }, [id])

  useEffect(() => {
    if ('NDEFReader' in window) {
      setNfcSupported(true)
    }
    if (id) {
      fetchCheckinConfig()
    }
  }, [id])

  useEffect(() => {
    let interval
    if (activeCheckin) {
      interval = setInterval(() => {
        const start = new Date(activeCheckin.checkin_time)
        const now = new Date()
        const diff = Math.floor((now - start) / 1000)
        
        const hours = Math.floor(diff / 3600)
        const minutes = Math.floor((diff % 3600) / 60)
        const seconds = diff % 60
        
        setFichajeTime(`${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`)
      }, 1000)
    }
    return () => clearInterval(interval)
  }, [activeCheckin])

  const fetchTaskDetails = async () => {
    try {
      const { data, error } = await supabase
        .from('tasks')
        .select(`
          *,
          task_assignments (
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

      const assignedUsers = []
      if (data.task_assignments) {
        data.task_assignments.forEach(assignment => {
          if (assignment.users) {
            assignedUsers.push(assignment.users)
          }
        })
      }

      setTask({
        ...data,
        assigned_users: assignedUsers
      })
    } catch (error) {
      console.error('Error fetching task:', error)
      toast.error('Error al cargar la tarea')
    } finally {
      setLoading(false)
    }
  }

  const fetchCheckinConfig = async () => {
    try {
      const { data, error } = await supabase
        .from('task_checkin_config')
        .select('*')
        .eq('task_id', id)
        .single()

      if (error) {
        console.error('Error config:', error)
        return
      }

      setCheckinConfig(data || {
        nfc_enabled: false,
        qr_enabled: true,
        manual_enabled: true
      })
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const fetchCheckins = async () => {
    try {
      const { data, error } = await supabase
        .from('checkins')
        .select(`
          *,
          users (
            id,
            full_name
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

  const fetchComments = async () => {
    try {
      const { data, error } = await supabase
        .from('task_comments')
        .select(`
          *,
          users (
            id,
            full_name
          )
        `)
        .eq('task_id', id)
        .order('created_at', { ascending: false })

      if (error) throw error
      setComments(data || [])
    } catch (error) {
      console.error('Error fetching comments:', error)
    }
  }

  const checkActiveCheckin = async () => {
    try {
      const { data, error } = await supabase
        .from('checkins')
        .select('*')
        .eq('task_id', id)
        .eq('user_id', userData.id)
        .is('checkout_time', null)
        .single()

      if (data) {
        setActiveCheckin(data)
      }
    } catch (error) {
      // No hay fichaje activo
    }
  }

  const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371e3
    const φ1 = lat1 * Math.PI / 180
    const φ2 = lat2 * Math.PI / 180
    const Δφ = (lat2 - lat1) * Math.PI / 180
    const Δλ = (lon2 - lon1) * Math.PI / 180

    const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ/2) * Math.sin(Δλ/2)
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))

    return R * c
  }

  const handleNFCCheckin = async () => {
    if (!nfcSupported) {
      toast.error('Tu dispositivo no soporta NFC')
      return
    }

    try {
      setIsReadingNFC(true)
      toast.info('🏷️ Acerca la tarjeta NFC al móvil...')

      const ndef = new NDEFReader()
      await ndef.scan()

      ndef.addEventListener('reading', async ({ serialNumber }) => {
        try {
          const { data, error } = await supabase.rpc('validate_nfc_checkin', {
            p_card_uid: serialNumber,
            p_task_id: id,
            p_user_id: userData.id
          })

          if (error) throw error

          if (data.success) {
            toast.success(data.message)
            
            if (data.type === 'checkin') {
              checkActiveCheckin()
            } else {
              setActiveCheckin(null)
              setFichajeTime(null)
            }
            
            fetchCheckins()
            fetchTaskDetails()
          } else {
            toast.error(data.message)
          }

        } catch (error) {
          console.error('Error procesando NFC:', error)
          toast.error('Error al procesar fichaje NFC')
        } finally {
          setIsReadingNFC(false)
        }
      }, { once: true })

    } catch (error) {
      console.error('Error NFC:', error)
      setIsReadingNFC(false)
      
      if (error.name === 'NotAllowedError') {
        toast.error('Permiso NFC denegado. Activa NFC en la configuración del móvil.')
      } else if (error.name === 'NotSupportedError') {
        toast.error('NFC no soportado en este navegador. Usa Chrome en Android.')
      } else {
        toast.error('Error al leer NFC: ' + error.message)
      }
    }
  }

  const handleStartCheckin = async () => {
    try {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords

          if (task.expected_latitude && task.expected_longitude) {
            const distance = calculateDistance(
              latitude,
              longitude,
              task.expected_latitude,
              task.expected_longitude
            )

            if (distance > task.location_radius) {
              const confirmOutside = window.confirm(
                `Estás a ${Math.round(distance)}m del punto esperado. ¿Deseas continuar con el fichaje?`
              )
              if (!confirmOutside) return
            }
          }

          const { data: newCheckin, error } = await supabase
            .from('checkins')
            .insert([{
              task_id: id,
              user_id: userData.id,
              location: `${latitude},${longitude}`,
              latitude: latitude,
              longitude: longitude,
              qr_code: 'Manual',
              checkin_method: 'manual'
            }])
            .select()
            .single()

          if (error) throw error

          await supabase
            .from('tasks')
            .update({
              status: 'in_progress',
              last_checkin: new Date().toISOString()
            })
            .eq('id', id)

          setActiveCheckin(newCheckin)
          toast.success('✅ Fichaje iniciado')
          fetchCheckins()
          fetchTaskDetails()
        },
        (error) => {
          toast.error('❌ No se pudo obtener la ubicación GPS')
        },
        { enableHighAccuracy: true, timeout: 10000 }
      )
    } catch (error) {
      console.error('Error starting checkin:', error)
      toast.error('Error al iniciar fichaje')
    }
  }

  const handleEndCheckin = async () => {
    try {
      const { error } = await supabase
        .from('checkins')
        .update({ checkout_time: new Date().toISOString() })
        .eq('id', activeCheckin.id)

      if (error) throw error

      setActiveCheckin(null)
      setFichajeTime(null)
      toast.success('✅ Fichaje finalizado')
      fetchCheckins()
    } catch (error) {
      console.error('Error ending checkin:', error)
      toast.error('Error al finalizar fichaje')
    }
  }

  const handleImageChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        toast.error('La imagen no debe superar 5MB')
        return
      }
      setCommentForm(prev => ({ ...prev, imageFile: file }))
      setImagePreview(URL.createObjectURL(file))
    }
  }

  const handleVideoChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      if (file.size > 50 * 1024 * 1024) {
        toast.error('El video no debe superar 50MB')
        return
      }
      setCommentForm(prev => ({ ...prev, videoFile: file }))
      setVideoPreview(URL.createObjectURL(file))
    }
  }

  const removeImage = () => {
    setCommentForm(prev => ({ ...prev, imageFile: null }))
    setImagePreview(null)
  }

  const removeVideo = () => {
    setCommentForm(prev => ({ ...prev, videoFile: null }))
    setVideoPreview(null)
  }

  const uploadFile = async (file, type) => {
    const fileExt = file.name.split('.').pop()
    const fileName = `${userData.id}-${Date.now()}.${fileExt}`
    const filePath = `${type}s/${fileName}`

    const { data, error } = await supabase.storage
      .from('task-files')
      .upload(filePath, file)

    if (error) throw error

    const { data: urlData } = supabase.storage
      .from('task-files')
      .getPublicUrl(filePath)

    return urlData.publicUrl
  }

  const handleAddComment = async (e) => {
    e.preventDefault()

    if (!commentForm.comment && !commentForm.imageFile && !commentForm.videoFile) {
      toast.error('Debes agregar un comentario o un archivo')
      return
    }

    try {
      setSubmitting(true)
      setUploadProgress(10)

      let imageUrl = null
      let videoUrl = null

      if (commentForm.imageFile) {
        setUploadProgress(30)
        imageUrl = await uploadFile(commentForm.imageFile, 'image')
        setUploadProgress(50)
      }

      if (commentForm.videoFile) {
        setUploadProgress(60)
        videoUrl = await uploadFile(commentForm.videoFile, 'video')
        setUploadProgress(80)
      }

      const { error } = await supabase
        .from('task_comments')
        .insert([{
          task_id: id,
          user_id: userData.id,
          comment: commentForm.comment || null,
          image_url: imageUrl,
          video_url: videoUrl
        }])

      if (error) {
        if (error.code === '42P01') {
          toast.error('La tabla de comentarios no existe en la base de datos')
        } else {
          throw error
        }
        return
      }

      setUploadProgress(100)
      toast.success('✅ Comentario agregado')
      
      setCommentForm({ comment: '', imageFile: null, videoFile: null })
      setImagePreview(null)
      setVideoPreview(null)
      setUploadProgress(0)
      
      fetchComments()
    } catch (error) {
      console.error('Error adding comment:', error)
      toast.error('Error al agregar comentario')
    } finally {
      setSubmitting(false)
    }
  }

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

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center min-h-screen">
          <div className="text-center space-y-4">
            <div className="animate-spin rounded-full h-16 w-16 border-4 border-blue-600 border-t-transparent mx-auto"></div>
            <p className="text-gray-600 font-medium">Cargando tarea...</p>
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
            <AlertDescription className="text-red-800">
              <strong>Error:</strong> No se encontró la tarea.
            </AlertDescription>
          </Alert>
          <Button onClick={() => navigate('/employee')} className="mt-4">
            Volver a Mis Tareas
          </Button>
        </div>
      </Layout>
    )
  }

  const statusBadge = getStatusBadge(task.status)

  return (
    <Layout>
      <div className="max-w-6xl mx-auto space-y-6">
        {/* Header con navegación */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button
              variant="outline"
              size="icon"
              onClick={() => navigate('/employee')}
            >
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">{task.title}</h1>
              <p className="text-gray-600 mt-1">{task.description || 'Sin descripción'}</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Badge 
              variant="outline" 
              className={`${statusBadge.bg} ${statusBadge.text} ${statusBadge.border} border font-medium`}
            >
              {statusBadge.label}
            </Badge>
            {task.schedule_type && getScheduleTypeBadge(task.schedule_type)}
          </div>
        </div>

        {/* Información General */}
        <Card className="border-2 shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Info className="h-5 w-5 text-blue-600" />
              Información de la Tarea
            </CardTitle>
          </CardHeader>
          <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {task.due_date && (
              <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                <Calendar className="h-5 w-5 text-gray-500" />
                <div>
                  <p className="text-xs text-gray-500 font-medium">Fecha límite</p>
                  <p className="text-sm font-semibold text-gray-900">
                    {format(new Date(task.due_date), 'PPP', { locale: es })}
                  </p>
                </div>
              </div>
            )}

            <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
              <Users className="h-5 w-5 text-gray-500" />
              <div>
                <p className="text-xs text-gray-500 font-medium">Asignada a</p>
                <p className="text-sm font-semibold text-gray-900">
                  {task.assigned_users?.map(u => u.full_name).join(', ') || 'Sin asignar'}
                </p>
              </div>
            </div>

            {task.location && (
              <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                <MapPin className="h-5 w-5 text-gray-500" />
                <div>
                  <p className="text-xs text-gray-500 font-medium">Ubicación</p>
                  <p className="text-sm font-semibold text-gray-900">{task.location}</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Control de Fichaje */}
        <Card className="border-2 shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="h-5 w-5 text-purple-600" />
              Control de Fichaje
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {activeCheckin ? (
              <div className="space-y-4">
                <Alert className="bg-blue-50 border-blue-200 border-2">
                  <Activity className="h-5 w-5 text-blue-600" />
                  <AlertDescription>
                    <div className="font-semibold text-blue-900">Fichaje activo</div>
                    <div className="text-3xl font-mono font-bold text-blue-600 mt-2">{fichajeTime}</div>
                    <div className="text-sm text-blue-700 mt-1">
                      Iniciado: {format(new Date(activeCheckin.checkin_time), "HH:mm", { locale: es })}
                    </div>
                  </AlertDescription>
                </Alert>

                {checkinConfig.nfc_enabled && nfcSupported ? (
                  <Button
                    onClick={handleNFCCheckin}
                    disabled={isReadingNFC}
                    className="w-full bg-blue-600 hover:bg-blue-700"
                    size="lg"
                  >
                    <NfcIcon className="mr-2 h-5 w-5" />
                    {isReadingNFC ? 'Leyendo NFC...' : 'Finalizar con NFC'}
                  </Button>
                ) : (
                  <Button
                    onClick={handleEndCheckin}
                    className="w-full bg-red-600 hover:bg-red-700"
                    size="lg"
                  >
                    <Square className="mr-2 h-5 w-5" />
                    Finalizar Fichaje Manual
                  </Button>
                )}
              </div>
            ) : (
              <div className="space-y-4">
                {checkinConfig.nfc_enabled && nfcSupported && (
                  <Button
                    onClick={handleNFCCheckin}
                    disabled={isReadingNFC}
                    className="w-full bg-blue-600 hover:bg-blue-700"
                    size="lg"
                  >
                    <NfcIcon className="mr-2 h-5 w-5" />
                    {isReadingNFC ? 'Leyendo NFC...' : 'Fichar con NFC'}
                  </Button>
                )}

                {checkinConfig.manual_enabled && (
                  <Button
                    onClick={handleStartCheckin}
                    className="w-full bg-green-600 hover:bg-green-700"
                    size="lg"
                  >
                    <Play className="mr-2 h-5 w-5" />
                    Iniciar Fichaje Manual
                  </Button>
                )}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Historial de Fichajes */}
        <Card className="border-2 shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              <span className="flex items-center gap-2">
                <Timer className="h-5 w-5 text-orange-600" />
                Historial de Fichajes
              </span>
              {checkins.length > 0 && (
                <Badge variant="outline" className="bg-orange-100 text-orange-800 border-orange-200 border">
                  {checkins.length} registros
                </Badge>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {checkins.length > 0 ? (
              <div className="rounded-lg border-2 overflow-hidden">
                <Table>
                  <TableHeader>
                    <TableRow className="bg-gray-50">
                      <TableHead className="font-bold">Empleado</TableHead>
                      <TableHead className="font-bold">Inicio</TableHead>
                      <TableHead className="font-bold">Fin</TableHead>
                      <TableHead className="font-bold">Método</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {checkins.map((checkin) => (
                      <TableRow key={checkin.id} className="hover:bg-gray-50">
                        <TableCell className="font-medium">{checkin.users?.full_name}</TableCell>
                        <TableCell>
                          {format(new Date(checkin.checkin_time), "dd/MM/yyyy HH:mm", { locale: es })}
                        </TableCell>
                        <TableCell>
                          {checkin.checkout_time ? 
                            format(new Date(checkin.checkout_time), "dd/MM/yyyy HH:mm", { locale: es }) :
                            <Badge variant="outline" className="bg-blue-100 text-blue-800 border-blue-200 border">
                              En curso
                            </Badge>
                          }
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline" className="bg-gray-100 text-gray-800 border-gray-200 border">
                            {checkin.checkin_method === 'nfc' && '🏷️ NFC'}
                            {checkin.checkin_method === 'qr' && '📱 QR'}
                            {checkin.checkin_method === 'manual' && '✋ Manual'}
                            {!checkin.checkin_method && '✋ Manual'}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            ) : (
              <div className="text-center py-8 bg-gray-50 rounded-lg">
                <p className="text-gray-500">No hay fichajes registrados</p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Comentarios */}
        <Card className="border-2 shadow-sm">
          <CardHeader>
            <CardTitle>Comentarios y Archivos</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            <form onSubmit={handleAddComment} className="space-y-4">
              <div>
                <Label htmlFor="comment">Agregar comentario</Label>
                <Textarea
                  id="comment"
                  placeholder="Escribe un comentario..."
                  value={commentForm.comment}
                  onChange={(e) => setCommentForm(prev => ({ ...prev, comment: e.target.value }))}
                  rows={3}
                />
              </div>

              <div className="flex gap-4">
                <div className="flex-1">
                  <Label htmlFor="image">
                    <div className="flex items-center gap-2 cursor-pointer">
                      <ImageIcon className="h-4 w-4" />
                      Imagen (máx 5MB)
                    </div>
                  </Label>
                  <Input
                    id="image"
                    type="file"
                    accept="image/*"
                    onChange={handleImageChange}
                    className="mt-1"
                  />
                </div>

                <div className="flex-1">
                  <Label htmlFor="video">
                    <div className="flex items-center gap-2 cursor-pointer">
                      <Video className="h-4 w-4" />
                      Video (máx 50MB)
                    </div>
                  </Label>
                  <Input
                    id="video"
                    type="file"
                    accept="video/*"
                    onChange={handleVideoChange}
                    className="mt-1"
                  />
                </div>
              </div>

              {imagePreview && (
                <div className="relative inline-block">
                  <img src={imagePreview} alt="Preview" className="h-32 rounded-lg" />
                  <Button
                    type="button"
                    variant="destructive"
                    size="sm"
                    className="absolute -top-2 -right-2"
                    onClick={removeImage}
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
              )}

              {videoPreview && (
                <div className="relative inline-block">
                  <video src={videoPreview} className="h-32 rounded-lg" controls />
                  <Button
                    type="button"
                    variant="destructive"
                    size="sm"
                    className="absolute -top-2 -right-2"
                    onClick={removeVideo}
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
              )}

              {uploadProgress > 0 && uploadProgress < 100 && (
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className="bg-blue-600 h-2 rounded-full transition-all"
                    style={{ width: `${uploadProgress}%` }}
                  />
                </div>
              )}

              <Button type="submit" disabled={submitting} className="w-full">
                <Upload className="mr-2 h-4 w-4" />
                {submitting ? 'Subiendo...' : 'Agregar Comentario'}
              </Button>
            </form>

            <div className="space-y-4">
              {comments.map((comment) => (
                <div key={comment.id} className="border-2 rounded-lg p-4 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-semibold">{comment.users?.full_name}</span>
                    <span className="text-sm text-gray-500">
                      {format(new Date(comment.created_at), "dd/MM/yyyy HH:mm", { locale: es })}
                    </span>
                  </div>
                  {comment.comment && (
                    <p className="text-gray-700">{comment.comment}</p>
                  )}
                  {comment.image_url && (
                    <img src={comment.image_url} alt="Attachment" className="max-w-md rounded-lg" />
                  )}
                  {comment.video_url && (
                    <video src={comment.video_url} controls className="max-w-md rounded-lg" />
                  )}
                </div>
              ))}

              {comments.length === 0 && (
                <p className="text-center text-gray-500 py-4">
                  No hay comentarios
                </p>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </Layout>
  )
}