import { useState, useEffect } from 'react'
import { toast } from 'sonner'
import Layout from '@/components/layout/Layout'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { 
  QrCode, 
  Download, 
  Copy,
  ArrowLeft,
  Calendar,
  Users,
  Info,
  CheckCircle
} from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import QRCodeStyling from 'qr-code-styling'

export default function QRGenerator() {
  const navigate = useNavigate()
  const [tasks, setTasks] = useState([])
  const [selectedTask, setSelectedTask] = useState(null)
  const [qrCode, setQrCode] = useState(null)
  const [qrSize, setQrSize] = useState(256)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchTasks()
  }, [])

  useEffect(() => {
    if (selectedTask && qrCode) {
      generateQRCode()
    }
  }, [qrSize])

  const fetchTasks = async () => {
    try {
      setLoading(true)
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
        .order('created_at', { ascending: false })

      if (error) throw error

      const tasksWithUsers = data.map(task => {
        const assignedUsers = []
        if (task.task_assignments) {
          task.task_assignments.forEach(assignment => {
            if (assignment.users) {
              assignedUsers.push(assignment.users)
            }
          })
        }
        return {
          ...task,
          assigned_users: assignedUsers,
          assigned_names: assignedUsers.length > 0 
            ? assignedUsers.map(u => u.full_name).join(', ') 
            : 'Sin asignar'
        }
      })

      setTasks(tasksWithUsers)
    } catch (error) {
      console.error('Error fetching tasks:', error)
      toast.error('Error al cargar las tareas')
    } finally {
      setLoading(false)
    }
  }

  const handleTaskSelect = (taskId) => {
    const task = tasks.find(t => t.id === taskId)
    setSelectedTask(task)
    if (task) {
      generateQRCode(task)
    }
  }

  const generateQRCode = (task = selectedTask) => {
    if (!task) return

    const qrData = JSON.stringify({
      task_id: task.id,
      task_title: task.title,
      type: 'task_checkin'
    })

    const qr = new QRCodeStyling({
      width: qrSize,
      height: qrSize,
      data: qrData,
      margin: 10,
      qrOptions: { typeNumber: 0, mode: 'Byte', errorCorrectionLevel: 'Q' },
      imageOptions: { hideBackgroundDots: true, imageSize: 0.4, margin: 0 },
      dotsOptions: {
        color: '#000000',
        type: 'rounded'
      },
      backgroundOptions: { color: '#ffffff' },
      cornersSquareOptions: { color: '#000000', type: 'extra-rounded' },
      cornersDotOptions: { color: '#000000', type: 'dot' }
    })

    setQrCode(qr)

    setTimeout(() => {
      const container = document.getElementById('qr-code-container')
      if (container) {
        container.innerHTML = ''
        qr.append(container)
      }
    }, 100)
  }

  const downloadQRCode = () => {
    if (!qrCode) return
    qrCode.download({ name: `qr-${selectedTask?.title || 'tarea'}`, extension: 'png' })
    toast.success('📥 Código QR descargado')
  }

  const copyToClipboard = (text, type) => {
    navigator.clipboard.writeText(text)
    toast.success(`📋 ${type} copiado al portapapeles`)
  }

  const getEmployeeUrl = () => {
    if (!selectedTask) return ''
    return `${window.location.origin}/employee/task/${selectedTask.id}/work`
  }

  const getAdminUrl = () => {
    if (!selectedTask) return ''
    return `${window.location.origin}/admin/task/${selectedTask.id}`
  }

  return (
    <Layout>
      <div className="space-y-6 max-w-6xl mx-auto">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">📱 Generar Código QR</h1>
            <p className="text-gray-900 mt-1">Genera códigos QR para las tareas del hotel</p>
          </div>
          <Button variant="outline" onClick={() => navigate('/admin')} className="text-gray-900">
            <ArrowLeft className="mr-2 h-4 w-4" />
            Volver
          </Button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <CardHeader className="bg-gradient-to-r from-blue-500 to-blue-600 text-white">
              <CardTitle className="flex items-center gap-2">
                <QrCode className="h-5 w-5" />
                Seleccionar Tarea
              </CardTitle>
            </CardHeader>
            <CardContent className="pt-6 space-y-4">
              <Alert className="bg-blue-50 border-blue-200">
                <Info className="h-4 w-4 text-blue-600" />
                <AlertDescription className="text-blue-800 text-sm">
                  Genera un código QR único para cada tarea. Los empleados podrán escanearlo para registrar su fichaje.
                </AlertDescription>
              </Alert>

              <div className="space-y-2">
                <label className="text-sm font-medium text-gray-900">Selecciona una tarea:</label>
                {loading ? (
                  <div className="text-center py-4">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto"></div>
                  </div>
                ) : (
                  <Select value={selectedTask?.id || ''} onValueChange={handleTaskSelect}>
                    <SelectTrigger className="text-gray-900">
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
                )}
              </div>

              {selectedTask && (
                <div className="space-y-3 border-t pt-4">
                  <h3 className="font-semibold text-gray-900">{selectedTask.title}</h3>
                  <p className="text-sm text-gray-900">{selectedTask.description || 'Sin descripción'}</p>
                  
                  {selectedTask.schedule_date && (
                    <div className="flex items-center gap-2 text-sm text-gray-900">
                      <Calendar className="h-4 w-4" />
                      <span>{new Date(selectedTask.schedule_date).toLocaleDateString('es-ES')}</span>
                    </div>
                  )}

                  <div className="flex items-start gap-2">
                    <Users className="h-4 w-4 text-gray-500 mt-0.5" />
                    <div className="flex-1">
                      <p className="text-sm font-medium text-gray-900">Empleados asignados:</p>
                      {selectedTask.assigned_users.length > 0 ? (
                        <ul className="text-sm text-gray-900 mt-1 space-y-1">
                          {selectedTask.assigned_users.map((user) => (
                            <li key={user.id} className="flex items-center gap-2">
                              <CheckCircle className="h-3 w-3 text-green-600" />
                              {user.full_name} ({user.email})
                            </li>
                          ))}
                        </ul>
                      ) : (
                        <p className="text-sm text-red-600 mt-1">⚠️ Sin empleados asignados</p>
                      )}
                    </div>
                  </div>

                  <div className="pt-2">
                    <label className="text-sm font-medium text-gray-900">URLs generadas:</label>
                    <div className="space-y-2 mt-2">
                      <div className="flex items-center gap-2">
                        <div className="flex-1">
                          <p className="text-xs text-gray-900 font-medium">Empleados:</p>
                          <code className="text-xs bg-blue-50 px-2 py-1 rounded block text-blue-700 break-all">
                            {getEmployeeUrl()}
                          </code>
                        </div>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => copyToClipboard(getEmployeeUrl(), 'URL de Empleados')}
                        >
                          <Copy className="h-4 w-4" />
                        </Button>
                      </div>

                      <div className="flex items-center gap-2">
                        <div className="flex-1">
                          <p className="text-xs text-gray-900 font-medium">Admin:</p>
                          <code className="text-xs bg-purple-50 px-2 py-1 rounded block text-purple-700 break-all">
                            {getAdminUrl()}
                          </code>
                        </div>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => copyToClipboard(getAdminUrl(), 'URL de Admin')}
                        >
                          <Copy className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-2 pt-2">
                    <label className="text-sm font-medium text-gray-900">Tamaño del código QR:</label>
                    <Select value={qrSize.toString()} onValueChange={(value) => setQrSize(parseInt(value))}>
                      <SelectTrigger className="text-gray-900">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="128">Pequeño (128px)</SelectItem>
                        <SelectItem value="256">Mediano (256px)</SelectItem>
                        <SelectItem value="512">Grande (512px)</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="bg-gradient-to-r from-green-500 to-green-600 text-white">
              <CardTitle className="flex items-center gap-2">
                <QrCode className="h-5 w-5" />
                Código QR Generado
              </CardTitle>
            </CardHeader>
            <CardContent className="pt-6">
              {selectedTask ? (
                <div className="space-y-4">
                  <div className="flex justify-center bg-white p-8 rounded-lg border-2 border-gray-200">
                    <div id="qr-code-container"></div>
                  </div>

                  <div className="text-center">
                    <h3 className="font-semibold text-gray-900">{selectedTask.title}</h3>
                    <p className="text-sm text-gray-900 mt-1">Escanea para fichar</p>
                  </div>

                  <Button
                    onClick={downloadQRCode}
                    className="w-full bg-green-500 hover:bg-green-600 text-white"
                  >
                    <Download className="mr-2 h-4 w-4" />
                    Descargar Código QR
                  </Button>

                  <Alert className="bg-green-50 border-green-200">
                    <Info className="h-4 w-4 text-green-600" />
                    <AlertDescription className="text-green-800 text-sm">
                      <strong>💡 Cómo usar:</strong>
                      <ul className="mt-2 space-y-1 text-xs list-disc list-inside">
                        <li>Imprime el código QR y colócalo en el lugar de trabajo</li>
                        <li>Los empleados lo escanean con su móvil</li>
                        <li>El sistema registra automáticamente el fichaje</li>
                        <li>Se valida la ubicación GPS si está configurada</li>
                      </ul>
                    </AlertDescription>
                  </Alert>
                </div>
              ) : (
                <div className="text-center py-12">
                  <QrCode className="h-16 w-16 text-gray-300 mx-auto mb-4" />
                  <p className="text-gray-900">Selecciona una tarea para generar el código QR</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </Layout>
  )
}