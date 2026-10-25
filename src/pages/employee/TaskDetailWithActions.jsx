import {ImportanceBadge} from '@/components/TaskImportance'
import {ScheduleText} from '@/components/planning/ExecutionSchedule'
import TaskChecklist from '@/components/checklists/TaskChecklist'
import TaskNfcControl from '@/components/TaskNfcControl'
import IncidentReporter from '@/components/IncidentReporter'
import { useState, useEffect, useRef } from 'react'
import { useParams, useNavigate, useSearchParams } from 'react-router-dom'
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
  FileText,
  X,
  Activity,
  Timer,
  Play,
  Square
} from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { useAuth } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase'
import {workRpc} from '@/lib/workflow'
import { signedTaskAttachment, taskAttachmentExtension, taskAttachmentId } from '@/lib/taskAttachments'

export default function TaskDetailWithActions() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const historyOnly = searchParams.get('view')==='history'
  const requestedPlan = searchParams.get('plan')
  const { userData } = useAuth()

  const [task, setTask] = useState(null)
  const [accessDenied, setAccessDenied] = useState(false)
  const [tabletMode, setTabletMode] = useState(false)
  const [checkins, setCheckins] = useState([])
  const [comments, setComments] = useState([])
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [activeCheckin, setActiveCheckin] = useState(null)
  const [incidentBlocked,setIncidentBlocked] = useState(false)
  const observedActiveCheckin = useRef(null)
  useEffect(()=>{observedActiveCheckin.current=activeCheckin},[activeCheckin])
  const incidentReporter = useRef(null)
  const imagePicker = useRef(null)
  const videoPicker = useRef(null)
  const filePicker = useRef(null)
  const incidentSection = useRef(null)
  const openIncident = () => {
    if (!canAct) return
    incidentReporter.current?.open()
    requestAnimationFrame(()=>incidentSection.current?.scrollIntoView({behavior:'smooth',block:'start'}))
  }
  const [endingCheckin, setEndingCheckin] = useState(false)
  const [changingPause,setChangingPause] = useState(false)
  const [finishedNotice, setFinishedNotice] = useState(false)
  const [activeCheckinStatus, setActiveCheckinStatus] = useState('loading')
  const [fichajeTime, setFichajeTime] = useState(null)
  const [queueItem,setQueueItem] = useState(null)
  const [queueReady,setQueueReady] = useState(false)
  const [nextPlanId,setNextPlanId] = useState(null)
  const [queueError,setQueueError] = useState('')
  const loadQueue = async () => {
    const {data,error} = await supabase.rpc('work_mobile_queue')
    if(error){setQueueReady(false);setQueueError(['PGRST202','42883'].includes(error.code)?'Falta activar la actualización del orden de tareas en Supabase.':`No se pudo verificar el orden (${error.code || 'conexión'}): ${error.message || 'Sin respuesta'}`);return}
    const item=requestedPlan?data?.items?.find(row=>row.plan_id===requestedPlan&&row.task_id===id):data?.items?.find(row=>row.plan_id===data?.next_plan&&row.task_id===id)||data?.items?.find(row=>row.task_id===id&&['active','paused'].includes(row.state))||null
    setQueueItem(item||null);setNextPlanId(data?.next_plan||null);setQueueReady(true)
  }
  useEffect(()=>{setQueueItem(null);setQueueReady(false);if(userData?.id)loadQueue()},[id,requestedPlan,userData?.id])
  const returnToTasks = () => navigate('/employee',{replace:true})

  const canStart = !incidentBlocked && !historyOnly && queueReady && nextPlanId===queueItem?.plan_id && queueItem?.task_id===id && queueItem?.can_start===true
  const canResume = !incidentBlocked && !historyOnly && queueReady && queueItem?.task_id===id && queueItem?.state==='paused' && queueItem?.can_resume===true
  const canAct = !incidentBlocked && !historyOnly && Boolean(userData?.is_admin || (activeCheckin?.task_id===id && activeCheckinStatus === 'ready' && activeCheckin && !activeCheckin.checkout_time))

  const handleIncidentReported = ({blocked}) => {
    if (!blocked) return
    setIncidentBlocked(true)
    setActiveCheckin(null)
    setActiveCheckinStatus('ready')
    setFichajeTime(null)
    toast.success('Fichaje detenido. Tarea bloqueada por incidencia, sin completarla.')
    navigate('/employee',{replace:true})
  }


  const [checkinConfig, setCheckinConfig] = useState({
    nfc_enabled: false,
    qr_enabled: true,
    manual_enabled: true
  })

  const [commentForm, setCommentForm] = useState({
    comment: '',
    imageFile: null,
    videoFile: null,
    file: null
  })
  const [mentionOptions,setMentionOptions] = useState([])
  const [mentions,setMentions] = useState([])

  useEffect(()=>{
    let live=true
    setMentionOptions([]);setMentions([])
    if(!id||!userData?.id)return()=>{live=false}
    workRpc('work_comment_recipients',{p_task:id}).then(items=>{if(live)setMentionOptions(items||[])}).catch(()=>{})
    return()=>{live=false}
  },[id,userData?.id])

  const [imagePreview, setImagePreview] = useState(null)
  const [videoPreview, setVideoPreview] = useState(null)
  const [uploadProgress, setUploadProgress] = useState(0)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setFinishedNotice(false)
    setIncidentBlocked(false)
    setTask(null)
    setAccessDenied(false)
    setCheckins([])
    setComments([])
    setActiveCheckin(null)
    setFichajeTime(null)
    setActiveCheckinStatus('loading')
    if (id && userData?.id) {
      fetchTaskDetails(() => !cancelled).then(allowed => {
        if (allowed && !cancelled) {
          fetchCheckins()
          fetchComments()
          checkActiveCheckin()
          fetchCheckinConfig()
        }
      })
    }
    return () => { cancelled = true }
  }, [id, userData?.id, userData?.is_admin])

  // Administrative board changes must also reach an employee using the mobile flow.
  useEffect(()=>{
    if(!id||!userData?.id)return
    let live=true,running=false
    const refresh=async()=>{
      if(!live||running||document.hidden)return
      running=true
      try{
        const {data,error}=await supabase.from('checkins').select('*').eq('task_id',id).eq('user_id',userData.id).is('checkout_time',null).maybeSingle()
        if(!live||error)return
        const previous=observedActiveCheckin.current
        if(previous?.task_id===id&&previous.id&&!data){
          observedActiveCheckin.current=null;setActiveCheckin(null);setActiveCheckinStatus('ready');setFichajeTime(null)
          toast.info('La tarea ha cambiado. Volvemos a tus tareas asignadas.')
          navigate('/employee',{replace:true});return
        }
        if(data?.id&&data.id!==previous?.id){observedActiveCheckin.current=data;setActiveCheckin(data);setActiveCheckinStatus('ready');loadQueue();await fetchTaskDetails(()=>live);if(live)fetchCheckins()}
      }finally{running=false}
    }
    const timer=setInterval(()=>refresh().catch(()=>{}),10000)
    const onFocus=()=>refresh().catch(()=>{})
    window.addEventListener('focus',onFocus)
    return()=>{live=false;clearInterval(timer);window.removeEventListener('focus',onFocus)}
  },[tabletMode,id,userData?.id,navigate])

  useEffect(() => {
    let interval
    if (activeCheckin && !incidentBlocked) {
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
  }, [activeCheckin,incidentBlocked])

  const fetchTaskDetails = async (isCurrent = () => true) => {
    try {
      if (!userData?.id) return false
      const { data: access, error: accessError } = await supabase.rpc('work_detail_access', { p_task_id: id })
      const migrationMissing = accessError?.code === 'PGRST202' || accessError?.code === '42883'
      if (accessError && !migrationMissing) throw accessError
      if (!isCurrent()) return false
      const enabled = !migrationMissing && access?.enabled === true
      setTabletMode(enabled)
      if (enabled && !access?.allowed) {
        setAccessDenied(true); setTask(null); setComments([]); setCheckins([]); setActiveCheckin(null)
        setImagePreview(null); setVideoPreview(null)
        return false
      }
      if (!userData.is_admin) {
        const { data: assignment, error: assignmentError } = await supabase
          .from('task_assignments')
          .select('id')
          .eq('task_id', id)
          .eq('user_id', userData.id)
          .maybeSingle()
        if (!isCurrent()) return false
        if (assignmentError) throw assignmentError
        const {data: resolver, error: resolverError} = assignment ? {data:false,error:null} : await supabase.rpc('work_incident_resolver',{p_task:id})
        if (!assignment && (resolverError || !resolver)) {
          setAccessDenied(true)
          setTask(null)
          return false
        }
      }
      const { data, error } = await supabase
        .from('tasks')
        .select(`
          *,
          task_assignments!task_assignments_task_id_fkey (
            user_id,
            users (
              id,
              full_name,
              email
            )
          )
        `)
        .eq('id', id)
        .maybeSingle()

      if (!isCurrent()) return false
      if (error) throw error
      if (!data) {
        setAccessDenied(true)
        setTask(null)
        return false
      }

      const assignedUsers = []
      if (data.task_assignments) {
        data.task_assignments.forEach(assignment => {
          if (assignment.users) {
            assignedUsers.push(assignment.users)
          }
        })
      }

      setAccessDenied(false)
      setTask({
        ...data,
        status: enabled && !userData.is_admin ? 'in_progress' : data.status,
        assigned_users: assignedUsers
      })
      return true
    } catch (error) {
      if (isCurrent()) {
        setTask(null)
        console.error('Error fetching task:', error?.code || 'unknown')
        toast.error('No se pudo comprobar el acceso a la tarea')
      }
      return false
    } finally {
      if (isCurrent()) setLoading(false)
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

  const fetchTaskActorNames = async () => {
    const { data, error } = await supabase.rpc('sec06_task_actor_names', { p_task_id: id })
    // Keep the current UI usable during the staged SQL installation.
    // Fallback uses only the existing RLS-filtered join; never another profile query.
    if (error?.code === 'PGRST202') return new Map()
    if (error) throw error
    return new Map((data || []).map(actor => [actor.id, { id: actor.id, full_name: actor.full_name }]))
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
      const actorNames = await fetchTaskActorNames()
      setCheckins((data || []).map(checkin => ({
        ...checkin,
        users: actorNames.get(checkin.user_id) || checkin.users
      })))
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
      const actorNames = await fetchTaskActorNames()
      const visibleComments = await Promise.all((data || []).map(async comment => {
        const [image, video, file] = await Promise.allSettled([
          comment.image_url ? signedTaskAttachment(comment.image_url) : Promise.resolve(null),
          comment.video_url ? signedTaskAttachment(comment.video_url) : Promise.resolve(null),
          comment.file_url ? signedTaskAttachment(comment.file_url) : Promise.resolve(null)
        ])
        return {
          ...comment,
          users: actorNames.get(comment.user_id) || comment.users,
          image_display_url: image.status === 'fulfilled' ? image.value : null,
          video_display_url: video.status === 'fulfilled' ? video.value : null,
          file_display_url: file.status === 'fulfilled' ? file.value : null,
          attachmentError: image.status === 'rejected' || video.status === 'rejected' || file.status === 'rejected'
        }
      }))
      setComments(visibleComments)
    } catch (error) {
      console.error('Error fetching comments:', error)
    }
  }

  // Refresh short-lived links while this task remains open.
  useEffect(() => {
    if (!id || !userData?.id || task?.id !== id) return
    const interval = setInterval(() => fetchComments(), 10 * 60 * 1000)
    return () => clearInterval(interval)
  }, [id, userData?.id, task?.id])

  const checkActiveCheckin = async () => {
    if (!userData?.id) return
    setActiveCheckinStatus('loading')
    try {
      const { data, error } = await supabase
        .from('checkins')
        .select('*')
        .eq('task_id', id)
        .eq('user_id', userData.id)
        .is('checkout_time', null)
        .maybeSingle()
      if (error) throw error
      setActiveCheckin(data || null)
      setActiveCheckinStatus('ready')
    } catch (error) {
      setActiveCheckinStatus('error')
      console.error('Error al recuperar fichaje:', error?.code || 'unknown')
      toast.error('No se pudo comprobar el fichaje activo. Recarga antes de iniciar otro.')
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
    if (!canStart) { toast.info('Esta tarea está disponible solo para consulta'); return }
    if (tabletMode) { toast.info('Confirma esta acción en la tablet'); return }
    if (!task || !userData?.id || activeCheckin) return
    const hasCoordinate = (value) => value !== null && value !== undefined && String(value).trim() !== ''
    const requiresGps = hasCoordinate(task.expected_latitude) && hasCoordinate(task.expected_longitude)
    try {
      let latitude = null
      let longitude = null
      if (requiresGps) {
        if (!window.isSecureContext) {
          toast.error('Esta tarea requiere GPS y necesita una conexión HTTPS. Abre ASE Work desde su dirección segura para fichar.')
          return
        }
        if (!navigator.geolocation) {
          toast.error('Este navegador no permite obtener la ubicación. Usa un navegador compatible con el GPS.')
          return
        }
        let position
        try {
          position = await new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(resolve, reject, { enableHighAccuracy: true, timeout: 10000 })
          })
        } catch (error) {
          const messages = {
            1: 'Permiso de ubicación denegado. Permite la ubicación para ASE Work en los ajustes del navegador.',
            2: 'La ubicación no está disponible. Comprueba que la localización del teléfono esté activada y vuelve a intentarlo.',
            3: 'Se agotó el tiempo para obtener la ubicación. Busca un lugar con mejor señal y vuelve a intentarlo.'
          }
          toast.error(messages[error.code] || 'No se pudo obtener la ubicación GPS. Vuelve a intentarlo.')
          return
        }
        ;({ latitude, longitude } = position.coords)
        const distance = calculateDistance(latitude, longitude, task.expected_latitude, task.expected_longitude)
        if (distance > task.location_radius) {
          const confirmOutside = window.confirm(`Estás a ${Math.round(distance)}m del punto esperado. ¿Deseas continuar con el fichaje?`)
          if (!confirmOutside) return
        }
      }

      const { data: newCheckin, error } = await supabase
        .from('checkins')
        .insert([{
          task_id: id,
          user_id: userData.id,
          location: requiresGps ? `${latitude},${longitude}` : null,
          latitude,
          longitude,
          qr_code: 'Manual',
          checkin_method: 'manual'
        }])
        .select()
        .single()
      if (error) throw error

      await supabase.from('tasks').update({ status: 'in_progress', last_checkin: new Date().toISOString() }).eq('id', id)
      setActiveCheckin(newCheckin)
      toast.success('✅ Fichaje iniciado')
      fetchCheckins()
      fetchTaskDetails()
    } catch (error) {
      console.error('Error starting checkin:', error)
      toast.error('Error al iniciar fichaje')
    }
  }

  const handleEndCheckin = async () => {
    if (tabletMode) { toast.info('Confirma esta acción en la tablet'); return }
    if (!activeCheckin?.id || endingCheckin) return
    setEndingCheckin(true)
    try {
      const { data, error } = await supabase.rpc('finish_manual_checkin', {
        p_checkin_id: activeCheckin.id
      })
      if (error) throw error
      if (!data?.success || data.checkin_id !== activeCheckin.id || !data.checkout_time) {
        throw new Error('El servidor no confirmó el cierre')
      }
      setActiveCheckin(null)
      setFichajeTime(null)
      setFinishedNotice(true)
      toast.success('Fichaje finalizado y guardado')
      returnToTasks()
    } catch (error) {
      console.error('Error al finalizar fichaje:', error?.code || 'unknown')
      toast.error(error?.message || 'No se confirmó el cierre. El fichaje sigue pendiente; puedes reintentar sin duplicarlo.')
    } finally {
      setEndingCheckin(false)
    }
  }

  const handlePauseResume = async action => {
    if(tabletMode){toast.info('Confirma esta acción en la tablet');return}
    if(changingPause||!queueItem?.plan_id)return
    setChangingPause(true)
    try{
      const result=await workRpc('work_pause_execution',{p_plan:queueItem.plan_id,p_action:action,p_reason:action==='pause'?'Pausa indicada por el empleado':'Reanudación indicada por el empleado',p_request:crypto.randomUUID()})
      if(!result?.success)throw Error('El servidor no confirmó la acción')
      toast.success(action==='pause'?'Tarea pausada. El tiempo queda guardado.':'Tarea reanudada con un nuevo tramo de tiempo.')
      if(action==='pause')returnToTasks();else{await loadQueue();await checkActiveCheckin();await fetchCheckins()}
    }catch(error){toast.error(error?.message||'No se pudo cambiar la pausa')}
    finally{setChangingPause(false)}
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

  const handleFileChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      try { taskAttachmentExtension(file, 'file'); setCommentForm(prev=>({...prev,file})) }
      catch (error) { toast.error(error.message) }
    }
  }

  const uploadFile = async (file, type) => {
    if (!id || !userData?.id) throw new Error('No hay sesión o tarea disponible')
    const extension = taskAttachmentExtension(file, type)
    const filePath = `tasks/${id}/${userData.id}/${taskAttachmentId()}.${extension}`
    const { error } = await supabase.storage.from('task-files').upload(filePath, file, {
      contentType: file.type,
      upsert: false
    })
    if (error) throw error
    return filePath
  }

  const handleAddComment = async (e) => {
    e.preventDefault()

    if (!canAct) { toast.error('Debes fichar en esta tarea antes de añadir comentarios o archivos.'); return }
    if (!commentForm.comment.trim()) {
      toast.error('Escribe un comentario para acompañar los archivos.')
      return
    }

    try {
      // Validate both files before uploading either one.
      if (commentForm.imageFile) taskAttachmentExtension(commentForm.imageFile, 'image')
      if (commentForm.videoFile) taskAttachmentExtension(commentForm.videoFile, 'video')
      if (commentForm.file) taskAttachmentExtension(commentForm.file, 'file')
      setSubmitting(true)
      setUploadProgress(10)

      let imageUrl = null
      let videoUrl = null
      let fileUrl = null

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

      if (commentForm.file) {
        setUploadProgress(85)
        fileUrl = await uploadFile(commentForm.file, 'file')
        setUploadProgress(90)
      }

      await workRpc('work_add_task_comment',{p_task:id,p_comment:commentForm.comment.trim(),p_image:imageUrl,p_video:videoUrl,p_file:fileUrl,p_mentions:mentions})

      setUploadProgress(100)
      toast.success('✅ Comentario agregado')

      setCommentForm({ comment: '', imageFile: null, videoFile: null, file: null })
      setMentions([])
      setImagePreview(null)
      setVideoPreview(null)
      setUploadProgress(0)

      fetchComments()
    } catch (error) {
      console.error('Error adding comment:', error?.code || 'unknown')
      toast.error(error instanceof Error ? error.message : 'Error al agregar comentario')
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
      blocked: {bg:'bg-amber-100',text:'text-amber-800',border:'border-amber-200',label:'Bloqueada por incidencia'},
      paused: {bg:'bg-orange-100',text:'text-orange-800',border:'border-orange-200',label:'Pausada'},
      review: {bg:'bg-violet-100',text:'text-violet-800',border:'border-violet-200',label:'En revisión'},
      cancelled: {bg:'bg-slate-100',text:'text-slate-800',border:'border-slate-200',label:'Cancelada'},
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
              <strong>{accessDenied ? 'Acceso no permitido:' : 'Tarea no disponible:'}</strong>{' '}
              {accessDenied ? (tabletMode ? 'Solo puedes abrir la tarea que tienes en curso. Comienza tu siguiente tarea en la tablet.' : 'No tienes asignada esta tarea o ya no está disponible.') : 'No se pudo cargar la tarea. Inténtalo de nuevo.'}
            </AlertDescription>
          </Alert>

        </div>
      </Layout>
    )
  }

  const statusBadge = getStatusBadge(incidentBlocked || queueItem?.state==='blocked' ? 'blocked' : activeCheckin ? 'in_progress' : ({active:'in_progress',paused:'paused',review:'review',cancelled:'cancelled',completed:'completed',pending:'pending'}[queueItem?.state]||task.status))

  return (
    <Layout>
      <div className="max-w-6xl mx-auto space-y-6">
        {/* Header con navegación */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex flex-wrap min-w-0 items-center gap-4">

            <div>
              <h1 className="text-3xl font-bold text-gray-900">{task.title}</h1>
              <p className="text-gray-600 mt-1">{task.description || 'Sin descripción'}</p>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <Badge
              variant="outline"
              className={`${statusBadge.bg} ${statusBadge.text} ${statusBadge.border} border font-medium`}
            >
              {statusBadge.label}
            </Badge>
            <ImportanceBadge value={task.importance}/>{task.schedule_type && getScheduleTypeBadge(task.schedule_type)}
          </div>
        </div>

        {/* Información General */}
        <Card className="border-2 shadow-sm">
          <CardHeader>
            <CardTitle className="flex flex-wrap items-center gap-2">
              <Info className="h-5 w-5 text-blue-600" />
              Información de la Tarea
            </CardTitle>
          </CardHeader>
          <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="md:col-span-2 p-3 bg-gray-50 rounded-lg"><p className="text-xs text-gray-500 font-medium">Cuándo debe hacerse</p><ScheduleText item={queueItem}/></div>
            {task.estimated_minutes&&<div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg"><Timer className="h-5 w-5 text-gray-500"/><div><p className="text-xs text-gray-500 font-medium">Tiempo estimado</p><p className="text-sm font-semibold text-gray-900">{Number(task.estimated_minutes).toLocaleString('es-ES')} min</p></div></div>}
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
            {(task.source_module || task.related_entity_reference) && (
              <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg md:col-span-2">
                <ExternalLink className="h-5 w-5 text-gray-500" />
                <div>
                  <p className="text-xs text-gray-500 font-medium">Origen relacionado</p>
                  <p className="text-sm font-semibold text-gray-900">{[task.source_module,task.related_entity_type,task.related_entity_reference,task.related_entity_label].filter(Boolean).join(' · ')}</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Control de Fichaje */}
        <Card className="border-2 shadow-sm">
          <CardHeader>
            <CardTitle className="flex flex-wrap items-center gap-2">
              <Clock className="h-5 w-5 text-purple-600" />
              Control de Fichaje
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {incidentBlocked ? <p role="status" className="text-gray-600">Fichaje detenido. La tarea está bloqueada por incidencia y no está completada.</p> : historyOnly ? <p className="text-gray-600">Solo consulta. Aquí puedes ver el historial y los comentarios; no se pueden realizar acciones.</p> : tabletMode ? <div className="space-y-4">
              <p className="text-gray-600">El inicio y la finalización se confirman únicamente en la tablet. Desde aquí puedes consultar la tarea y añadir fotos y comentarios.</p>
              {activeCheckin && <div className="rounded-lg border border-blue-200 bg-blue-50 p-4"><p className="text-blue-800 font-medium">Tu fichaje sigue activo</p><p className="font-mono text-3xl text-blue-700 mt-2">{fichajeTime || '00:00:00'}</p></div>}
            </div> : <>
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

                <Button variant="outline" className="w-full" disabled={changingPause} onClick={()=>handlePauseResume('pause')}>{changingPause?'Guardando pausa…':'Pausar trabajo'}</Button>

                {activeCheckin.checkin_method === 'nfc' && checkinConfig.nfc_enabled ? (
                  <TaskNfcControl onFinished={returnToTasks} taskId={id} userId={userData?.id} activeCheckin={activeCheckin} checkinStatus={activeCheckinStatus} onChanged={async()=>{await checkActiveCheckin();await fetchCheckins()}} />
                ) : (
                  <Button
                    onClick={handleEndCheckin}
                    disabled={endingCheckin || activeCheckin.checkin_method !== 'manual'}
                    className="w-full bg-red-600 hover:bg-red-700"
                    size="lg"
                  >
                    <Square className="mr-2 h-5 w-5" />
                    {endingCheckin ? 'Guardando salida…' : 'Finalizar Fichaje Manual'}
                  </Button>
                )}
              </div>
            ) : (
              <div className="space-y-4">
                {!queueReady ? <p role="status">{queueError || 'Comprobando el orden y la fecha…'} <button className="underline" onClick={loadQueue}>Reintentar</button></p> : !canStart&&!canResume && <p className="text-gray-600">{queueItem?.state==='completed'?'Tarea finalizada. Solo puedes consultar el historial y los comentarios.':queueItem?.starts_later?'Todavía no está disponible según su programación.':queueItem?.overdue?'La fecha límite ha pasado. Solicita al encargado que reprograme la ejecución.':'Solo consulta. El inicio se habilita cuando sea tu siguiente tarea según el orden del encargado.'}</p>}
                {canResume&&<Button className="w-full" size="lg" disabled={changingPause} onClick={()=>handlePauseResume('resume')}><Play className="mr-2 h-5 w-5"/>{changingPause?'Reanudando…':'Reanudar trabajo'}</Button>}
                {checkinConfig.nfc_enabled && canStart && (
                  <TaskNfcControl onFinished={returnToTasks} taskId={id} userId={userData?.id} activeCheckin={activeCheckin} checkinStatus={activeCheckinStatus} onChanged={async()=>{await checkActiveCheckin();await fetchCheckins()}} />
                )}

                {activeCheckinStatus !== 'ready' && (
                  <p role="status" className="text-sm text-gray-600">
                    {activeCheckinStatus === 'loading'
                      ? 'Comprobando si hay un fichaje abierto…'
                      : 'No se pudo comprobar el fichaje. Recarga antes de iniciar otro.'}
                  </p>
                )}
                {checkinConfig.manual_enabled && canStart && (
                  <Button
                    onClick={handleStartCheckin}
                    disabled={activeCheckinStatus !== 'ready'}
                    className="w-full bg-green-600 hover:bg-green-700"
                    size="lg"
                  >
                    <Play className="mr-2 h-5 w-5" />
                    Iniciar Fichaje Manual
                  </Button>
                )}
              </div>
            )}
            </>}
          </CardContent>
        </Card>

        <TaskChecklist key={id} taskId={id} userId={userData?.id} activeCheckin={activeCheckin} checkins={checkins} readOnly={!canAct}/>
        {/* Historial de Fichajes */}
        <Card className="border-2 shadow-sm">
          <CardHeader>
            <CardTitle className="flex flex-wrap items-center justify-between gap-3">
              <span className="flex flex-wrap items-center gap-2">
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
                        <TableCell className="font-medium">{checkin.users?.full_name || 'Usuario no disponible'}</TableCell>
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

        {finishedNotice && <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4"><section role="dialog" aria-modal="true" aria-label="Actividad finalizada" className="bg-white rounded-lg p-6 space-y-4 w-full max-w-md text-center"><CheckCircle className="h-12 w-12 text-blue-600 mx-auto"/><p className="font-semibold">Fichaje finalizado y guardado</p><Button className="w-full bg-blue-600 hover:bg-blue-700" onClick={returnToTasks}>Salir</Button></section></div>}
        {/* Comentarios */}
        <Card className="border-2 shadow-sm">
          <CardHeader>
            <CardTitle>Comentarios y Archivos</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {(task?.require_comment||task?.require_photo||task?.require_video||task?.require_file)&&<Alert><Info className="h-4 w-4"/><AlertDescription><strong>Para finalizar esta tarea debes aportar:</strong> {[task.require_comment&&'comentario',task.require_photo&&'foto',task.require_video&&'vídeo',task.require_file&&'archivo'].filter(Boolean).join(', ')} durante este fichaje.</AlertDescription></Alert>}
            {canAct ? <form onSubmit={handleAddComment} className="space-y-4">
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

              {mentionOptions.length>0&&<fieldset className="rounded-lg border border-blue-200 bg-blue-50/60 p-3"><legend className="px-1 text-sm font-semibold text-blue-900">Mencionar a alguien · opcional</legend><p className="mb-3 text-xs text-blue-800">La persona recibirá un aviso destacado, sin mostrar el contenido del comentario.</p><div className="grid sm:grid-cols-2 gap-2">{mentionOptions.map(person=><label key={person.id} className="flex items-center gap-2 rounded-md border bg-white p-2 text-sm"><input type="checkbox" className="h-4 w-4 accent-blue-600" checked={mentions.includes(person.id)} onChange={e=>setMentions(current=>e.target.checked?[...current,person.id]:current.filter(id=>id!==person.id))}/><span>{person.name}<span className="block text-xs text-gray-500">{person.role}</span></span></label>)}</div></fieldset>}

              <div className="grid sm:grid-cols-3 gap-4">
                <div className="flex-1 min-w-0">
                  <Label htmlFor="image">
                    <div className="flex items-center gap-2 cursor-pointer">
                      <ImageIcon className="h-4 w-4" />
                      Imagen (máx 5MB)
                    </div>
                  </Label>
                  <Input
                    id="image"
                    ref={imagePicker}
                    type="file"
                    accept="image/png,image/jpeg,image/gif,image/webp"
                    onChange={handleImageChange}
                    className="hidden"
                    tabIndex={-1}
                  />
                  <Button type="button" variant="outline" className="mt-1 w-full min-w-0 h-auto min-h-10 whitespace-normal px-2 py-2" aria-label="Seleccionar archivos de imagen" onClick={()=>imagePicker.current?.click()}>Seleccionar archivos</Button>
                </div>

                <div className="flex-1 min-w-0">
                  <Label htmlFor="video">
                    <div className="flex items-center gap-2 cursor-pointer">
                      <Video className="h-4 w-4" />
                      Video (máx 50MB)
                    </div>
                  </Label>
                  <Input
                    id="video"
                    ref={videoPicker}
                    type="file"
                    accept="video/mp4,video/webm,video/quicktime"
                    onChange={handleVideoChange}
                    className="hidden"
                    tabIndex={-1}
                  />
                  <Button type="button" variant="outline" className="mt-1 w-full min-w-0 h-auto min-h-10 whitespace-normal px-2 py-2" aria-label="Seleccionar archivos de vídeo" onClick={()=>videoPicker.current?.click()}>Seleccionar archivos</Button>
                </div>
                <div className="flex-1 min-w-0">
                  <Label htmlFor="evidence-file"><div className="flex items-center gap-2 cursor-pointer"><FileText className="h-4 w-4"/>Archivo (máx 50MB)</div></Label>
                  <Input id="evidence-file" ref={filePicker} type="file" accept=".pdf,.doc,.docx,.xls,.xlsx,.csv,.txt" onChange={handleFileChange} className="hidden" tabIndex={-1}/>
                  <Button type="button" variant="outline" className="mt-1 w-full min-w-0 h-auto min-h-10 whitespace-normal px-2 py-2" onClick={()=>filePicker.current?.click()}>Seleccionar archivo</Button>
                  {commentForm.file&&<p className="mt-1 text-xs break-all">{commentForm.file.name} · <button type="button" className="underline" onClick={()=>setCommentForm(v=>({...v,file:null}))}>Quitar</button></p>}
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
            </form> : <p className="text-sm text-gray-600">Ficha en esta tarea para añadir comentarios, archivos o reportar incidencias. Puedes consultar el historial.</p>}

            <div className="space-y-4">
              {comments.map((comment) => (
                <div key={comment.id} className="border-2 rounded-lg p-4 space-y-2">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <span className="font-semibold">{comment.users?.full_name || 'Usuario no disponible'}</span>
                    <span className="text-sm text-gray-500">
                      {format(new Date(comment.created_at), "dd/MM/yyyy HH:mm", { locale: es })}
                    </span>
                  </div>
                  {comment.comment && (
                    <p className="text-gray-700">{comment.comment}</p>
                  )}
                  {comment.image_display_url && (
                    <img src={comment.image_display_url} alt="Attachment" className="w-full max-w-md rounded-lg" />
                  )}
                  {comment.video_display_url && (
                    <video src={comment.video_display_url} controls className="w-full max-w-md rounded-lg" />
                  )}
                  {comment.file_display_url && <a className="inline-flex items-center gap-2 text-blue-700 underline" href={comment.file_display_url} target="_blank" rel="noreferrer"><FileText className="h-4 w-4"/>Abrir archivo adjunto</a>}
                  {comment.attachmentError && (
                    <div role="status" className="text-sm text-amber-800">
                      No se pudo obtener acceso al adjunto.{' '}
                      <button type="button" className="underline" onClick={fetchComments}>Reintentar</button>
                    </div>
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
        {canAct && <Button type="button" variant="outline" className="w-full min-h-12" onClick={openIncident}>Reportar incidencia</Button>}
        {(canAct || incidentBlocked) && <div ref={incidentSection}><IncidentReporter ref={incidentReporter} taskId={id} hideTrigger onReported={handleIncidentReported}/></div>}
      </div>
    </Layout>
  )
}
