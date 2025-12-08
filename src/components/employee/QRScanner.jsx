import { useState, useRef } from 'react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Info, CheckCircle } from 'lucide-react'
import { useAuth } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase'

export default function QRScanner({ onClose }) {
  const { userData } = useAuth()
  const [scanning, setScanning] = useState(false)
  const [qrData, setQrData] = useState('')
  const fileInputRef = useRef(null)

  const handleFileUpload = async (event) => {
    const file = event.target.files?.[0]
    if (!file) return

    setScanning(true)

    try {
      // Aquí iría la lógica de escaneo de QR
      // Por ahora usamos input manual
      toast.info('Funcionalidad de escaneo en desarrollo')
      toast.info('Por favor, ingresa el código QR manualmente')
    } catch (error) {
      console.error('Error scanning QR:', error)
      toast.error('Error al escanear el código QR')
    } finally {
      setScanning(false)
    }
  }

  const handleManualSubmit = async () => {
    if (!qrData.trim()) {
      toast.error('Por favor ingresa el código QR')
      return
    }

    try {
      setScanning(true)

      // Parsear datos del QR
      const data = JSON.parse(qrData)
      const taskId = data.task_id

      // Obtener ubicación actual
      const position = await new Promise((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject)
      })

      const { latitude, longitude } = position.coords

      // Registrar fichaje
      const { error } = await supabase
        .from('checkins')
        .insert([{
          task_id: taskId,
          user_id: userData.id,
          location: 'Ubicación registrada',
          latitude,
          longitude,
          qr_code: qrData.slice(0, 20)
        }])

      if (error) throw error

      // Actualizar última fecha de fichaje en la tarea
      await supabase
        .from('tasks')
        .update({
          last_checkin: new Date().toISOString(),
          checkin_latitude: latitude,
          checkin_longitude: longitude
        })
        .eq('id', taskId)

      toast.success('✅ Fichaje registrado correctamente')
      onClose()
    } catch (error) {
      console.error('Error registering checkin:', error)
      toast.error('Error al registrar el fichaje')
    } finally {
      setScanning(false)
    }
  }

  return (
    <div className="space-y-6">
      <Alert className="bg-blue-50 border-blue-200">
        <Info className="h-4 w-4 text-blue-600" />
        <AlertDescription className="text-blue-800">
          <strong>Cómo fichar:</strong>
          <ol className="mt-2 space-y-1 list-decimal list-inside text-sm">
            <li>Toma una foto del código QR de la tarea</li>
            <li>O ingresa manualmente el código QR</li>
            <li>Se registrará tu ubicación automáticamente</li>
          </ol>
        </AlertDescription>
      </Alert>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-semibold text-gray-900 mb-2">
            Ingresar Código QR Manualmente
          </label>
          <textarea
            value={qrData}
            onChange={(e) => setQrData(e.target.value)}
            placeholder='{"task_id":"...","task_title":"..."}'
            rows={4}
            className="w-full border border-gray-300 rounded-md p-3 font-mono text-sm"
          />
        </div>

        <Button
          onClick={handleManualSubmit}
          disabled={scanning}
          className="w-full bg-green-500 hover:bg-green-600 text-white"
          size="lg"
        >
          <CheckCircle className="mr-2 h-5 w-5" />
          {scanning ? 'Registrando...' : 'Registrar Fichaje'}
        </Button>

        <div className="relative">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-gray-300"></div>
          </div>
          <div className="relative flex justify-center text-sm">
            <span className="px-2 bg-white text-gray-500">O</span>
          </div>
        </div>

        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          capture="environment"
          onChange={handleFileUpload}
          className="hidden"
        />

        <Button
          onClick={() => fileInputRef.current?.click()}
          variant="outline"
          disabled={scanning}
          className="w-full"
          size="lg"
        >
          📷 Escanear con Cámara
        </Button>
      </div>
    </div>
  )
}