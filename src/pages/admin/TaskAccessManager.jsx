import { useState, useEffect } from 'react'
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
  const [tasks, setTasks] = useState([])
  const [accessCodes, setAccessCodes] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedTask, setSelectedTask] = useState(null)
  const [isGenerateModalOpen, setIsGenerateModalOpen] = useState(false)
  const [generatedCode, setGeneratedCode] = useState(null)
  const [expirationDays, setExpirationDays] = useState('never')

  useEffect(() => {
    fetchTasks()
    fetchAccessCodes()
  }, [])

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
      // Calcular fecha de expiración
      let expiresAt = null
      if (expirationDays !== 'never') {
        const days = parseInt(expirationDays)
        expiresAt = new Date()
        expiresAt.setDate(expiresAt.getDate() + days)
      }

      // Llamar a la función de base de datos
      const { data: codeData, error: codeError } = await supabase
        .rpc('generate_task_access_code', {
          p_task_id: selectedTask
        })

      if (codeError) throw codeError

      // Actualizar fecha de expiración si se especificó
      if (expiresAt) {
        const { error: updateError } = await supabase
          .from('task_access_codes')
          .update({ expires_at: expiresAt.toISOString() })
          .eq('access_code', codeData)

        if (updateError) throw updateError
      }

      setGeneratedCode(codeData)
      toast.success('✅ Código generado correctamente')
      
      // Recargar códigos
      await fetchAccessCodes()

    } catch (error) {
      console.error('Error generating code:', error)
      toast.error('Error al generar el código de acceso')
    }
  }

  const copyCodeToClipboard = (code) => {
    const url = `${window.location.origin}/task-access/${code}`
    navigator.clipboard.writeText(url)
    toast.success('📋 URL copiada al portapapeles')
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
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">🔐 Gestión de Códigos de Acceso</h1>
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
              <div className="rounded-md border">
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
                disabled={!selectedTask}
                className="w-full bg-green-500 hover:bg-green-600 text-white"
              >
                <Key className="mr-2 h-4 w-4" />
                Generar Código
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