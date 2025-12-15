import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Switch } from '@/components/ui/switch'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'
import { Settings, Save, NfcIcon, QrCode, Hand } from 'lucide-react'

interface Task {
  id: string
  title: string
  description: string
}

interface CheckinConfig {
  id: string
  task_id: string
  nfc_enabled: boolean
  qr_enabled: boolean
  manual_enabled: boolean
  created_at: string
  updated_at: string
}

interface ConfigsMap {
  [taskId: string]: CheckinConfig
}

export default function TaskCheckinMethodsConfig() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [configs, setConfigs] = useState<ConfigsMap>({})
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    fetchTasksAndConfigs()
  }, [])

  const fetchTasksAndConfigs = async () => {
    try {
      setLoading(true)

      const { data: tasksData, error: tasksError } = await supabase
        .from('tasks')
        .select('id, title, description')

      console.log('📋 Tareas obtenidas:', tasksData)
      console.log('❌ Error tareas:', tasksError)

      if (tasksError) throw tasksError

      const { data: configsData, error: configsError } = await supabase
        .from('task_checkin_config')
        .select('*')
 
      console.log('⚙️ Configs obtenidas:', configsData)
      console.log('❌ Error configs:', configsError)
      console.log('📋 Tareas obtenidas:', tasksData)
console.log('❌ Error tareas:', tasksError)
console.log('🚀🚀🚀 ARCHIVO CORRECTO CARGADO - SIN LOCATION 🚀🚀🚀')

      if (configsError) throw configsError

      const sortedTasks = (tasksData || []).sort((a, b) => 
        a.title.localeCompare(b.title)
      )

      setTasks(sortedTasks)

      const configsMap: ConfigsMap = {}
      configsData?.forEach(config => {
        configsMap[config.task_id] = config
      })
      setConfigs(configsMap)

    } catch (error) {
      console.error('❌ Error completo:', error)
      toast.error('Error al cargar configuración')
    } finally {
      setLoading(false)
    }
  }

  const handleToggle = (taskId: string, method: 'nfc' | 'qr' | 'manual') => {
    setConfigs(prev => ({
      ...prev,
      [taskId]: {
        ...prev[taskId],
        [`${method}_enabled`]: !prev[taskId]?.[`${method}_enabled`]
      }
    }))
  }

  const handleSave = async (taskId: string) => {
    try {
      setSaving(true)
      const config = configs[taskId]

      const { error } = await supabase
        .from('task_checkin_config')
        .update({
          nfc_enabled: config.nfc_enabled,
          qr_enabled: config.qr_enabled,
          manual_enabled: config.manual_enabled,
          updated_at: new Date().toISOString()
        })
        .eq('task_id', taskId)

      if (error) throw error

      toast.success('✅ Configuración guardada')
    } catch (error) {
      console.error('Error:', error)
      toast.error('Error al guardar configuración')
    } finally {
      setSaving(false)
    }
  }

  const handleSaveAll = async () => {
    try {
      setSaving(true)

      const updates = Object.entries(configs).map(([taskId, config]) => ({
        task_id: taskId,
        nfc_enabled: config.nfc_enabled,
        qr_enabled: config.qr_enabled,
        manual_enabled: config.manual_enabled,
        updated_at: new Date().toISOString()
      }))

      for (const update of updates) {
        const { error } = await supabase
          .from('task_checkin_config')
          .update(update)
          .eq('task_id', update.task_id)

        if (error) throw error
      }

      toast.success('✅ Todas las configuraciones guardadas')
    } catch (error) {
      console.error('Error:', error)
      toast.error('Error al guardar configuraciones')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Cargando configuración...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-3">
            <Settings className="h-8 w-8" />
            Métodos de Fichaje
          </h1>
          <p className="text-gray-600 mt-2">
            Configura qué métodos de fichaje están habilitados para cada tarea
          </p>
        </div>

        <Button
          onClick={handleSaveAll}
          disabled={saving}
          className="bg-green-600 hover:bg-green-700"
        >
          <Save className="mr-2 h-4 w-4" />
          Guardar Todo
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Leyenda de Métodos</CardTitle>
          <CardDescription>
            Descripción de cada método de fichaje disponible
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="flex items-start gap-3 p-4 border rounded-lg">
              <NfcIcon className="h-6 w-6 text-blue-600 flex-shrink-0 mt-1" />
              <div>
                <h3 className="font-semibold text-gray-900">NFC</h3>
                <p className="text-sm text-gray-600 mt-1">
                  El empleado acerca su móvil a una tarjeta NFC física. Solo Android.
                </p>
              </div>
            </div>

            <div className="flex items-start gap-3 p-4 border rounded-lg">
              <QrCode className="h-6 w-6 text-green-600 flex-shrink-0 mt-1" />
              <div>
                <h3 className="font-semibold text-gray-900">QR</h3>
                <p className="text-sm text-gray-600 mt-1">
                  El empleado escanea un código QR. iOS y Android.
                </p>
              </div>
            </div>

            <div className="flex items-start gap-3 p-4 border rounded-lg">
              <Hand className="h-6 w-6 text-orange-600 flex-shrink-0 mt-1" />
              <div>
                <h3 className="font-semibold text-gray-900">Manual</h3>
                <p className="text-sm text-gray-600 mt-1">
                  Botón directo. Uso excepcional.
                </p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="space-y-4">
        {tasks.map(task => {
          const config = configs[task.id] || {
            id: '',
            task_id: task.id,
            nfc_enabled: false,
            qr_enabled: true,
            manual_enabled: true,
            created_at: '',
            updated_at: ''
          }

          const enabledCount = [
            config.nfc_enabled,
            config.qr_enabled,
            config.manual_enabled
          ].filter(Boolean).length

          return (
            <Card key={task.id}>
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <CardTitle className="text-xl">{task.title}</CardTitle>
                    <CardDescription className="mt-1">
                      {task.description}
                    </CardDescription>
                  </div>
                  <Badge variant={enabledCount > 0 ? 'default' : 'secondary'}>
                    {enabledCount} método{enabledCount !== 1 ? 's' : ''}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors">
                    <div className="flex items-center gap-3">
                      <NfcIcon className={`h-6 w-6 ${config.nfc_enabled ? 'text-blue-600' : 'text-gray-400'}`} />
                      <div>
                        <Label htmlFor={`nfc-${task.id}`} className="text-base font-medium cursor-pointer">
                          Fichaje por NFC
                        </Label>
                        <p className="text-sm text-gray-600">
                          Requiere tarjeta NFC (solo Android)
                        </p>
                      </div>
                    </div>
                    <Switch
                      id={`nfc-${task.id}`}
                      checked={config.nfc_enabled}
                      onCheckedChange={() => handleToggle(task.id, 'nfc')}
                    />
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors">
                    <div className="flex items-center gap-3">
                      <QrCode className={`h-6 w-6 ${config.qr_enabled ? 'text-green-600' : 'text-gray-400'}`} />
                      <div>
                        <Label htmlFor={`qr-${task.id}`} className="text-base font-medium cursor-pointer">
                          Fichaje por QR
                        </Label>
                        <p className="text-sm text-gray-600">
                          iOS y Android
                        </p>
                      </div>
                    </div>
                    <Switch
                      id={`qr-${task.id}`}
                      checked={config.qr_enabled}
                      onCheckedChange={() => handleToggle(task.id, 'qr')}
                    />
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors">
                    <div className="flex items-center gap-3">
                      <Hand className={`h-6 w-6 ${config.manual_enabled ? 'text-orange-600' : 'text-gray-400'}`} />
                      <div>
                        <Label htmlFor={`manual-${task.id}`} className="text-base font-medium cursor-pointer">
                          Fichaje Manual
                        </Label>
                        <p className="text-sm text-gray-600">
                          Uso excepcional
                        </p>
                      </div>
                    </div>
                    <Switch
                      id={`manual-${task.id}`}
                      checked={config.manual_enabled}
                      onCheckedChange={() => handleToggle(task.id, 'manual')}
                    />
                  </div>

                  <div className="pt-2">
                    <Button
                      onClick={() => handleSave(task.id)}
                      disabled={saving}
                      className="w-full"
                      variant="outline"
                    >
                      <Save className="mr-2 h-4 w-4" />
                      Guardar configuración
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          )
        })}
      </div>

      {tasks.length === 0 && (
        <Card>
          <CardContent className="text-center py-12">
            <p className="text-gray-600">No hay tareas creadas.</p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}