import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import Layout from '@/components/layout/Layout'
import { useTasks } from '@/hooks/useTasks'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Badge } from '@/components/ui/badge'
import { QRCodeSVG } from 'qrcode.react'
import { ArrowLeft, Download, Share2, Info, Calendar, Users } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'

export default function QRGenerator() {
  const navigate = useNavigate()
  const { tasks, loading } = useTasks()
  const [selectedTaskId, setSelectedTaskId] = useState('')
  const [qrSize, setQrSize] = useState(256)

  const selectedTask = tasks.find(t => t.id === selectedTaskId)

  const handleDownloadQR = () => {
    if (!selectedTask) return

    const svg = document.getElementById('qr-code')
    const svgData = new XMLSerializer().serializeToString(svg)
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')
    const img = new Image()

    canvas.width = qrSize
    canvas.height = qrSize

    img.onload = () => {
      ctx.drawImage(img, 0, 0)
      const pngFile = canvas.toDataURL('image/png')
      const downloadLink = document.createElement('a')
      downloadLink.download = `QR-${selectedTask.title.replace(/\s+/g, '-')}.png`
      downloadLink.href = pngFile
      downloadLink.click()
    }

    img.src = 'data:image/svg+xml;base64,' + btoa(svgData)
  }

  const handlePrintQR = () => {
    window.print()
  }

  const getQRData = () => {
    if (!selectedTask) return ''
    
    const baseURL = window.location.origin
    return JSON.stringify({
      task_id: selectedTask.id,
      task_title: selectedTask.title,
      url_employee: `${baseURL}/employee/task/${selectedTask.id}`,
      url_admin: `${baseURL}/admin/task/${selectedTask.id}`,
      generated_at: new Date().toISOString()
    })
  }

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
            <p className="mt-4 text-gray-600">Cargando tareas...</p>
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
            <h1 className="text-3xl font-bold text-gray-900">📱 Generar Código QR</h1>
            <p className="text-gray-600 mt-1">Genera códigos QR para las tareas del hotel</p>
          </div>
          <Button
            variant="outline"
            onClick={() => navigate('/admin')}
            className="bg-gray-600 text-white hover:bg-gray-700 hover:text-white"
          >
            <ArrowLeft className="mr-2 h-4 w-4" />
            Volver al Panel
          </Button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Panel Izquierdo - Selección */}
          <Card>
            <CardHeader className="bg-gradient-to-r from-blue-500 to-blue-600 text-white">
              <CardTitle className="flex items-center gap-2">
                <span className="text-2xl">📋</span>
                Seleccionar Tarea
              </CardTitle>
            </CardHeader>
            <CardContent className="pt-6 space-y-6">
              <Alert className="bg-blue-50 border-blue-200">
                <Info className="h-4 w-4 text-blue-600" />
                <AlertDescription className="text-blue-800">
                  Genera un código QR único para cada tarea. Los empleados podrán escanearlo para registrar su fichaje.
                </AlertDescription>
              </Alert>

              <div className="space-y-2">
                <label className="text-sm font-semibold text-gray-900">
                  Selecciona una tarea:
                </label>
                <Select value={selectedTaskId} onValueChange={setSelectedTaskId}>
                  <SelectTrigger className="w-full border-gray-300">
                    <SelectValue placeholder="-- Selecciona una tarea --" />
                  </SelectTrigger>
                  <SelectContent>
                    {tasks.map((task) => (
                      <SelectItem key={task.id}