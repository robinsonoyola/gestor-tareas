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
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
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
  X
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

  const handleStartCheckin = async () => {
    try {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords

          let withinRange = true
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
              withinRange = false
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
              qr_code: 'Manual'
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

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
            <p className="mt-4 text-gray-900">Cargando tarea...</p>
          </div>
        </div>
      </Layout>
    )
  }

  if (!task) {
    return (
      <Layout>
        <div className="text-center py-12">
          <p className="text-gray-900">Tarea no encontrada</p>
          <Button onClick={() => navigate('/employee')} className="mt-4">
            Volver
          </Button>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="space-y-6 max-w-6xl mx-auto">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">📋 {task.title}</h1>
            <p className="text-gray-900 mt-1">{task.description}</p>
          </div>
          <Button variant="outline" onClick={() => navigate('/employee')} className="text-gray-900">
            ← Volver
          </Button>
        </div>

        {/* Información de la Tarea */}
        <Card>
          <CardHeader className="bg-gradient-to-r from-purple-500 to-pink-600 text-white">
            <CardTitle>📝 Información de la Tarea</CardTitle>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {task.schedule_date && (
                <div className="flex items-center gap-2 text-gray-900">
                  <Calendar className="h-5 w-5 text-purple-600" />
                  <div>
                    <p className="text-sm font-medium">Fecha Programada</p>
                    <p className="text-sm">{format(new Date(task.schedule_date), 'PPP', { locale: es })}</p>
                  </div>
                </div>
              )}

              <div className="flex items-center gap-2 text-gray-900">
                <Users className="h-5 w-5 text-blue-600" />
                <div>
                  <p className="text-sm font-medium">Asignados</p>
                  <p className="text-sm">{task.assigned_users.map(u => u.full_name).join(', ')}</p>
                </div>
              </div>

              {task.expected_latitude && task.expected_longitude && (
                <div className="flex items-center gap-2 text-gray-900">
                  <MapPin className="h-5 w-5 text-red-600" />
                  <div>
                    <p className="text-sm font-medium">Validación GPS</p>
                    <p className="text-sm">Radio: {task.location_radius}m</p>
                  </div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Control de Fichaje */}
        <Card>
          <CardHeader className="bg-gradient-to-r from-green-500 to-teal-600 text-white">
            <CardTitle>⏱️ Control de Fichaje</CardTitle>
          </CardHeader>
          <CardContent className="pt-6 space-y-4">
            {activeCheckin ? (
              <>
                <Alert className="bg-green-50 border-green-200">
                  <CheckCircle className="h-4 w-4 text-green-600" />
                  <AlertDescription className="text-green-800">
                    <strong>✅ Fichaje activo desde:</strong> {format(new Date(activeCheckin.checkin_time), 'PPp', { locale: es })}
                  </AlertDescription>
                </Alert>

                <div className="text-center py-8">
                  <Clock className="h-16 w-16 text-blue-600 mx-auto mb-4" />
                  <p className="text-6xl font-bold text-blue-600">{fichajeTime || '00:00:00'}</p>
                  <p className="text-sm text-gray-900 mt-2">Tiempo transcurrido</p>
                </div>

                <Button
                  onClick={handleEndCheckin}
                  className="w-full bg-red-500 hover:bg-red-600 text-white"
                  size="lg"
                >
                  ⏹ Finalizar Fichaje
                </Button>
              </>
            ) : (
              <>
                <Alert className="bg-blue-50 border-blue-200">
                  <Info className="h-4 w-4 text-blue-600" />
                  <AlertDescription className="text-blue-800 text-sm">
                    <strong>📍 Instrucciones:</strong> Al iniciar el fichaje, se registrará tu ubicación GPS.
                    {task.expected_latitude && ` Debes estar dentro de un radio de ${task.location_radius}m.`}
                  </AlertDescription>
                </Alert>

                <Button
                  onClick={handleStartCheckin}
                  className="w-full bg-green-500 hover:bg-green-600 text-white"
                  size="lg"
                >
                  ▶️ Iniciar Fichaje
                </Button>
              </>
            )}
          </CardContent>
        </Card>

        {/* Comentarios y Archivos */}
        <Card>
          <CardHeader className="bg-gradient-to-r from-orange-500 to-red-600 text-white">
            <CardTitle>💬 Comentarios y Archivos</CardTitle>
          </CardHeader>
          <CardContent className="pt-6 space-y-4">
            <form onSubmit={handleAddComment} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="comment" className="text-gray-900 font-semibold">
                  Escribir comentario
                </Label>
                <Textarea
                  id="comment"
                  value={commentForm.comment}
                  onChange={(e) => setCommentForm(prev => ({ ...prev, comment: e.target.value }))}
                  placeholder="Escribe aquí tus observaciones, notas o comentarios sobre la tarea..."
                  rows={4}
                  className="text-gray-900"
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="image" className="text-gray-900 font-semibold">
                    📸 Subir Imagen (opcional)
                  </Label>
                  <div className="flex items-center gap-2">
                    <Input
                      id="image"
                      type="file"
                      accept="image/*"
                      onChange={handleImageChange}
                      className="text-gray-900"
                      disabled={submitting}
                    />
                  </div>
                  {imagePreview && (
                    <div className="relative">
                      <img src={imagePreview} alt="Preview" className="w-full h-32 object-cover rounded border" />
                      <Button
                        type="button"
                        size="sm"
                        variant="destructive"
                        className="absolute top-2 right-2"
                        onClick={removeImage}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  )}
                  <p className="text-xs text-gray-600">Máximo 5MB</p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="video" className="text-gray-900 font-semibold">
                    🎥 Subir Video (opcional)
                  </Label>
                  <div className="flex items-center gap-2">
                    <Input
                      id="video"
                      type="file"
                      accept="video/*"
                      onChange={handleVideoChange}
                      className="text-gray-900"
                      disabled={submitting}
                    />
                  </div>
                  {videoPreview && (
                    <div className="relative">
                      <video src={videoPreview} className="w-full h-32 object-cover rounded border" controls />
                      <Button
                        type="button"
                        size="sm"
                        variant="destructive"
                        className="absolute top-2 right-2"
                        onClick={removeVideo}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  )}
                  <p className="text-xs text-gray-600">Máximo 50MB</p>
                </div>
              </div>

              {uploadProgress > 0 && uploadProgress < 100 && (
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className="bg-blue-600 h-2 rounded-full transition-all"
                    style={{ width: `${uploadProgress}%` }}
                  />
                </div>
              )}

              <Button
                type="submit"
                disabled={submitting}
                className="w-full bg-blue-500 hover:bg-blue-600 text-white"
              >
                {submitting ? '⏳ Subiendo...' : '💬 Agregar Comentario'}
              </Button>
            </form>

            <div className="border-t pt-4">
              <h3 className="font-semibold text-gray-900 mb-3">Comentarios anteriores</h3>
              {comments.length === 0 ? (
                <p className="text-center text-gray-600 py-8">📭 No hay comentarios aún. ¡Sé el primero en comentar!</p>
              ) : (
                <div className="space-y-3">
                  {comments.map((comment) => (
                    <div key={comment.id} className="bg-gray-50 rounded-lg p-4">
                      <div className="flex items-start justify-between mb-2">
                        <p className="font-semibold text-gray-900">{comment.users?.full_name}</p>
                        <p className="text-xs text-gray-600">{format(new Date(comment.created_at), 'PPp', { locale: es })}</p>
                      </div>
                      {comment.comment && (
                        <p className="text-sm text-gray-900 mb-2">{comment.comment}</p>
                      )}
                      {comment.image_url && (
                        <img
                          src={comment.image_url}
                          alt="Comentario"
                          className="w-full max-w-md h-auto rounded border mt-2"
                          onError={(e) => e.target.style.display = 'none'}
                        />
                      )}
                      {comment.video_url && (
                        <video
                          src={comment.video_url}
                          controls
                          className="w-full max-w-md h-auto rounded border mt-2"
                        />
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Historial de Fichajes */}
        <Card>
          <CardHeader>
            <CardTitle className="text-gray-900">📊 Historial de Fichajes</CardTitle>
          </CardHeader>
          <CardContent>
            {checkins.length === 0 ? (
              <p className="text-center text-gray-600 py-8">📭 No hay fichajes registrados</p>
            ) : (
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-gray-900">Entrada</TableHead>
                      <TableHead className="text-gray-900">Salida</TableHead>
                      <TableHead className="text-gray-900">Empleado</TableHead>
                      <TableHead className="text-gray-900">Duración</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {checkins.map((checkin) => {
                      const duration = checkin.checkout_time
                        ? Math.floor((new Date(checkin.checkout_time) - new Date(checkin.checkin_time)) / 1000 / 60)
                        : null

                      return (
                        <TableRow key={checkin.id}>
                          <TableCell className="text-gray-900">
                            {format(new Date(checkin.checkin_time), 'PPp', { locale: es })}
                          </TableCell>
                          <TableCell className="text-gray-900">
                            {checkin.checkout_time ? (
                              format(new Date(checkin.checkout_time), 'PPp', { locale: es })
                            ) : (
                              <Badge className="bg-green-100 text-green-800 border-0">En curso</Badge>
                            )}
                          </TableCell>
                          <TableCell className="text-gray-900">{checkin.users?.full_name}</TableCell>
                          <TableCell className="text-gray-900">
                            {duration !== null ? (
                              `${Math.floor(duration / 60)}h ${duration % 60}m`
                            ) : (
                              '-'
                            )}
                          </TableCell>
                        </TableRow>
                      )
                    })}
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