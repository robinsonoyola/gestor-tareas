import {MobileAccessCodes} from './MobileRecords'
import QRCodeStyling from 'qr-code-styling'
import { useSearchParams } from 'react-router-dom'
import { useState, useEffect, useRef, useCallback } from 'react'
import { toast } from 'sonner'
import Layout from '@/components/layout/Layout'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Alert, AlertDescription } from '@/components/ui/alert'
import {
  Key,
  QrCode,
  Download,
  Copy,
  ExternalLink,
  Trash2,
  Calendar,
  CheckCircle,
  AlertCircle,
  Plus,
  Link as LinkIcon
} from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { supabase } from '@/lib/supabase'

export default function TaskAccessManager() {
  const [query]=useSearchParams()
  const seenTask=useRef(null)
  const [qrAccess,setQrAccess]=useState(null)
  const [qrSize,setQrSize]=useState(256)
  const qrContainer=useRef(null)
  const qrInstance=useRef(null)
  const [tasks, setTasks] = useState([])
  const [employees, setEmployees] = useState([])
  const [responsibleUsers, setResponsibleUsers] = useState([])
  const [assignmentsLoading, setAssignmentsLoading] = useState(false)
  const [accessCodes, setAccessCodes] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedTask, setSelectedTask] = useState(null)
  const [isGenerateModalOpen, setIsGenerateModalOpen] = useState(false)
  const [generatedCode, setGeneratedCode] = useState(null)
  const [expirationDays, setExpirationDays] = useState('never')
  const [manualCopyUrl, setManualCopyUrl] = useState('')

  useEffect(() => {
    fetchTasks()
    fetchAccessCodes()
    fetchEmployees()
  }, [])

  useEffect(()=>{if(!selectedTask){setResponsibleUsers([]);return}let live=true;setAssignmentsLoading(true);supabase.from('task_assignments').select('user_id').eq('task_id',selectedTask).then(({data,error})=>{if(!live)return;if(error){toast.error('No se pudieron cargar los responsables');setResponsibleUsers([])}else setResponsibleUsers((data||[]).map(x=>x.user_id))}).finally(()=>{if(live)setAssignmentsLoading(false)});return()=>{live=false}},[selectedTask])

  const sharedTask=query.get('task')
  useEffect(()=>{
    if(sharedTask && sharedTask!==seenTask.current && tasks.some(t=>t.id===sharedTask)){
      seenTask.current=sharedTask;setSelectedTask(sharedTask);setGeneratedCode(null);setIsGenerateModalOpen(true)
    }
  },[sharedTask,tasks])
  const mountQr = useCallback(node => {
    qrContainer.current = node
    qrInstance.current = null
    if (!node || !qrAccess) return
    const qr = new QRCodeStyling({width:qrSize,height:qrSize,data:`${window.location.origin}/task-access/${qrAccess.access_code}`,margin:12,dotsOptions:{color:'#0F172A',type:'rounded'},cornersSquareOptions:{color:'#2F6BFF',type:'extra-rounded'},backgroundOptions:{color:'#FFFFFF'},qrOptions:{errorCorrectionLevel:'H'}})
    node.replaceChildren()
    qr.append(node)
    qrInstance.current = qr
  }, [qrAccess, qrSize])

  const fetchTasks = async () => {
    try {
      const { data, error } = await supabase
        .from('tasks')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error
      setTasks(data || [])
    } catch (error) {
      console.error('Error fetching tasks:', error)
      toast.error('Error al cargar las tareas')
    }
  }

  const fetchEmployees = async () => {
    const {data,error}=await supabase.rpc('work_employee_directory')
    if(error){toast.error('Error al cargar los empleados');return}
    setEmployees(data||[])
  }

  const fetchAccessCodes = async () => {
    try {
      setLoading(true)

      const { data, error } = await supabase
        .from('task_access_codes')
        .select(`
          *,
          tasks (
            id,
            title,
            status
          )
        `)
        .order('created_at', { ascending: false })

      if (error) throw error
      setAccessCodes(data || [])
    } catch (error) {
      console.error('Error fetching access codes:', error)
      toast.error('Error al cargar los códigos de acceso')
    } finally {
      setLoading(false)
    }
  }

  const generateAccessCode = async () => {
    if (!selectedTask) {
      toast.error('Selecciona una tarea primero')
      return
    }

    try {
      if (!responsibleUsers.length) { toast.error('Selecciona al menos un empleado responsable'); return }
      const { data: codeData, error: codeError } = await supabase
        .rpc('work_share_task_access', {
          p_task: selectedTask,
          p_users: responsibleUsers,
          p_expires_days: expirationDays==='never'?null:Number(expirationDays)
        })

      if (codeError) throw codeError
      setGeneratedCode(codeData.code)
      toast.success('✅ Responsables asignados y acceso generado')

      // Recargar códigos
      await fetchAccessCodes()

    } catch (error) {
      console.error('Error generating code:', error)
      toast.error(error?.message || 'Error al asignar responsables y generar el acceso')
    }
  }

  const copyCodeToClipboard = async (code) => {
    const url = `${window.location.origin}/task-access/${code}`
    if (window.isSecureContext && navigator.clipboard?.writeText) {
      try {
        await navigator.clipboard.writeText(url)
        toast.success('📋 URL copiada al portapapeles')
        return
      } catch {
        // Some browsers deny clipboard access; offer a selectable link below.
      }
    }
    const previousFocus = document.activeElement
    const field = document.createElement('textarea')
    field.value = url
    field.readOnly = true
    field.style.cssText = 'position:fixed;top:0;left:0;width:1px;height:1px;font-size:16px;'
    document.body.appendChild(field)
    let copied = false
    try {
      field.focus()
      field.select()
      field.setSelectionRange(0, url.length)
      copied = document.execCommand('copy') === true
    } catch {
      copied = false
    } finally {
      field.remove()
      previousFocus?.focus?.()
    }
    if (copied) toast.success('📋 URL copiada al portapapeles')
    else setManualCopyUrl(url)
  }

  const openCodeInNewTab = (code) => {
    const url = `${window.location.origin}/task-access/${code}`
    window.open(url, '_blank')
  }

  const deactivateCode = async (codeId) => {
    const confirm = window.confirm('¿Estás seguro de desactivar este código de acceso?')
    if (!confirm) return

    try {
      const { error } = await supabase
        .from('task_access_codes')
        .update({ is_active: false })
        .eq('id', codeId)

      if (error) throw error

      toast.success('✅ Código desactivado')
      await fetchAccessCodes()

    } catch (error) {
      console.error('Error deactivating code:', error)
      toast.error('Error al desactivar el código')
    }
  }

  const activateCode = async (codeId) => {
    try {
      const { error } = await supabase
        .from('task_access_codes')
        .update({ is_active: true })
        .eq('id', codeId)

      if (error) throw error

      toast.success('✅ Código activado')
      await fetchAccessCodes()

    } catch (error) {
      console.error('Error activating code:', error)
      toast.error('Error al activar el código')
    }
  }

  const isCodeExpired = (expiresAt) => {
    if (!expiresAt) return false
    return new Date(expiresAt) < new Date()
  }

  const getStatusBadge = (code) => {
    const expired = isCodeExpired(code.expires_at)

    if (!code.is_active) {
      return <Badge className="bg-gray-100 text-gray-800">❌ Inactivo</Badge>
    }

    if (expired) {
      return <Badge className="bg-red-100 text-red-800">⏰ Expirado</Badge>
    }

    return <Badge className="bg-green-100 text-green-800">✅ Activo</Badge>
  }

  const openGenerateModal = () => {
    setSelectedTask(null)
    setExpirationDays('never')
    setGeneratedCode(null)
    setIsGenerateModalOpen(true)
  }

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
            <p className="mt-4 text-gray-600">Cargando códigos de acceso...</p>
          </div>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <Dialog open={Boolean(qrAccess)} onOpenChange={open=>{if(!open)setQrAccess(null)}}><DialogContent className="max-w-xl max-h-[90vh] overflow-y-auto"><DialogHeader><DialogTitle>QR del acceso a la tarea</DialogTitle><DialogDescription>Este QR utiliza el mismo enlace, estado y caducidad que el código seleccionado. No sustituye la identificación personal del empleado.</DialogDescription></DialogHeader><div ref={mountQr} className="flex justify-center overflow-auto"/><div className="space-y-2"><Label htmlFor="access-qr-size">Tamaño de descarga</Label><select id="access-qr-size" className="w-full border bg-white rounded-md p-2" value={qrSize} onChange={e=>setQrSize(Number(e.target.value))}><option value={256}>256 px</option><option value={384}>384 px</option><option value={512}>512 px</option></select></div>{qrAccess && (!qrAccess.is_active || (qrAccess.expires_at && new Date(qrAccess.expires_at)<=new Date())) && <p className="text-sm text-red-700">Este acceso está desactivado o ha caducado.</p>}<Button onClick={()=>qrInstance.current?.download({name:'ASE-Work-acceso-'+qrAccess.id,extension:'png'})}><Download className="h-4 w-4 mr-2"/>Descargar QR</Button></DialogContent></Dialog>
      <Dialog open={Boolean(manualCopyUrl)} onOpenChange={(open) => { if (!open) setManualCopyUrl('') }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Copiar enlace de acceso</DialogTitle>
            <DialogDescription>El navegador no permite copiar automáticamente. Mantén pulsado el enlace, selecciona todo y pulsa Copiar.</DialogDescription>
          </DialogHeader>
          <Label htmlFor="manual-copy-url">Enlace de la tarea</Label>
          <Input id="manual-copy-url" value={manualCopyUrl} readOnly
            onFocus={(event) => event.target.select()}
            onClick={(event) => event.currentTarget.select()} />
        </DialogContent>
      </Dialog>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Enlaces y códigos QR</h1>
            <p className="text-gray-600 mt-1">Genera URLs únicas para que los empleados accedan a sus tareas</p>
          </div>
          <Button
            onClick={openGenerateModal}
            className="bg-green-500 hover:bg-green-600 text-white"
          >
            <Plus className="mr-2 h-4 w-4" />
            Generar Código
          </Button>
        </div>

        {/* Información */}
        <Alert className="bg-blue-50 border-blue-200">
          <AlertCircle className="h-4 w-4 text-blue-600" />
          <AlertDescription className="text-blue-800">
            <strong>💡 Cómo funciona:</strong> Genera un código único para cada tarea. Comparte la URL con los empleados.
            Ellos deberán ingresar sus credenciales para acceder.
          </AlertDescription>
        </Alert>

        {/* Estadísticas */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-blue-600">
                  {accessCodes.length}
                </div>
                <p className="text-sm text-gray-600 mt-2">Total Códigos</p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-green-600">
                  {accessCodes.filter(c => c.is_active && !isCodeExpired(c.expires_at)).length}
                </div>
                <p className="text-sm text-gray-600 mt-2">Activos</p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-red-600">
                  {accessCodes.filter(c => isCodeExpired(c.expires_at)).length}
                </div>
                <p className="text-sm text-gray-600 mt-2">Expirados</p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-gray-600">
                  {accessCodes.filter(c => !c.is_active).length}
                </div>
                <p className="text-sm text-gray-600 mt-2">Inactivos</p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Tabla de Códigos */}
        <Card>
          <CardHeader>
            <CardTitle>📋 Códigos de Acceso Generados</CardTitle>
          </CardHeader>
          <CardContent>
            {accessCodes.length === 0 ? (
              <div className="text-center py-12">
                <Key className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-600 mb-4">No hay códigos de acceso generados</p>
                <Button onClick={openGenerateModal}>
                  Generar Primer Código
                </Button>
              </div>
            ) : (
              <>
              <MobileAccessCodes items={accessCodes} statusBadge={getStatusBadge} onQR={setQrAccess} onCopy={copyCodeToClipboard} onOpen={openCodeInNewTab} onToggle={code=>code.is_active?deactivateCode(code.id):activateCode(code.id)}/>
              <div className="hidden md:block rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Tarea</TableHead>
                      <TableHead>Código</TableHead>
                      <TableHead>Estado</TableHead>
                      <TableHead>Creado</TableHead>
                      <TableHead>Expira</TableHead>
                      <TableHead className="text-right">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {accessCodes.map((code) => (
                      <TableRow key={code.id}>
                        <TableCell className="font-medium">
                          {code.tasks?.title || 'Tarea eliminada'}
                        </TableCell>
                        <TableCell>
                          <code className="bg-gray-100 px-2 py-1 rounded text-sm">
                            {code.access_code}
                          </code>
                        </TableCell>
                        <TableCell>
                          {getStatusBadge(code)}
                        </TableCell>
                        <TableCell className="text-sm text-gray-600">
                          {format(new Date(code.created_at), 'PPp', { locale: es })}
                        </TableCell>
                        <TableCell className="text-sm text-gray-600">
                          {code.expires_at ? (
                            format(new Date(code.expires_at), 'PPp', { locale: es })
                          ) : (
                            <span className="text-green-600">Sin expiración</span>
                          )}
                        </TableCell>
                        <TableCell className="text-right space-x-2">
                          <Button size="sm" variant="outline" onClick={()=>setQrAccess(code)} title="Ver y descargar QR" aria-label="Ver y descargar QR"><QrCode className="h-4 w-4"/></Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => copyCodeToClipboard(code.access_code)}
                            title="Copiar URL"
                          >
                            <Copy className="h-4 w-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => openCodeInNewTab(code.access_code)}
                            title="Abrir en nueva pestaña"
                          >
                            <ExternalLink className="h-4 w-4" />
                          </Button>
                          {code.is_active ? (
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => deactivateCode(code.id)}
                              className="text-red-600 hover:text-red-700"
                              title="Desactivar"
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          ) : (
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => activateCode(code.id)}
                              className="text-green-600 hover:text-green-700"
                              title="Activar"
                            >
                              <CheckCircle className="h-4 w-4" />
                            </Button>
                          )}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Modal para Generar Código */}
      <Dialog open={isGenerateModalOpen} onOpenChange={setIsGenerateModalOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>🔐 Generar Código de Acceso</DialogTitle>
            <DialogDescription>
              Crea un código único para que los empleados accedan a una tarea específica
            </DialogDescription>
          </DialogHeader>

          {!generatedCode ? (
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="task" className="text-gray-900 font-semibold">
                  Seleccionar Tarea *
                </Label>
                <Select value={selectedTask} onValueChange={setSelectedTask}>
                  <SelectTrigger>
                    <SelectValue placeholder="Selecciona una tarea..." />
                  </SelectTrigger>
                  <SelectContent>
                    {tasks.map((task) => (
                      <SelectItem key={task.id} value={task.id}>
                        {task.title}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label className="text-gray-900 font-semibold">Empleados responsables *</Label>
                <div className="rounded-md border p-3 space-y-2 max-h-48 overflow-y-auto">
                  {assignmentsLoading?<p className="text-sm text-gray-500">Cargando responsables…</p>:employees.length?employees.map(employee=><label key={employee.id} className="flex items-center gap-2 text-sm cursor-pointer"><input type="checkbox" checked={responsibleUsers.includes(employee.id)} onChange={e=>setResponsibleUsers(current=>e.target.checked?[...new Set([...current,employee.id])]:current.filter(id=>id!==employee.id))}/><span>{employee.full_name}</span></label>):<p className="text-sm text-gray-500">No hay empleados activos.</p>}
                </div>
                <p className="text-xs text-gray-500">Los empleados ya asignados aparecen marcados. No se puede retirar a quien tenga planificación pendiente, activa o bloqueada.</p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="expiration" className="text-gray-900 font-semibold">
                  Expiración del Código
                </Label>
                <Select value={expirationDays} onValueChange={setExpirationDays}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="never">Sin expiración</SelectItem>
                    <SelectItem value="1">1 día</SelectItem>
                    <SelectItem value="7">7 días</SelectItem>
                    <SelectItem value="30">30 días</SelectItem>
                    <SelectItem value="90">90 días</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <Button
                onClick={generateAccessCode}
                disabled={!selectedTask || !responsibleUsers.length || assignmentsLoading}
                className="w-full bg-green-500 hover:bg-green-600 text-white"
              >
                <Key className="mr-2 h-4 w-4" />
                Asignar y generar acceso
              </Button>
            </div>
          ) : (
            <div className="space-y-4">
              <Alert className="bg-green-50 border-green-200">
                <CheckCircle className="h-4 w-4 text-green-600" />
                <AlertDescription className="text-green-800">
                  <strong>✅ Código generado exitosamente</strong>
                </AlertDescription>
              </Alert>

              <div className="space-y-2">
                <Label className="text-gray-900 font-semibold">
                  URL de Acceso:
                </Label>
                <div className="flex gap-2">
                  <Input
                    value={`${window.location.origin}/task-access/${generatedCode}`}
                    readOnly
                    className="font-mono text-sm"
                  />
                  <Button
                    onClick={() => copyCodeToClipboard(generatedCode)}
                    variant="outline"
                  >
                    <Copy className="h-4 w-4" />
                  </Button>
                </div>
              </div>

              <Alert className="bg-blue-50 border-blue-200">
                <LinkIcon className="h-4 w-4 text-blue-600" />
                <AlertDescription className="text-blue-800 text-sm">
                  <strong>💡 Importante:</strong> Comparte esta URL con los empleados asignados a la tarea.
                  Necesitarán ingresar sus credenciales para acceder.
                </AlertDescription>
              </Alert>

              <div className="flex gap-2">
                <Button
                  onClick={() => openCodeInNewTab(generatedCode)}
                  className="flex-1"
                  variant="outline"
                >
                  <ExternalLink className="mr-2 h-4 w-4" />
                  Abrir URL
                </Button>
                <Button
                  onClick={() => {
                    setIsGenerateModalOpen(false)
                    setGeneratedCode(null)
                  }}
                  className="flex-1"
                >
                  Cerrar
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </Layout>
  )
}
