import { useNavigate } from 'react-router-dom'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Calendar, Users, Clock, AlertCircle } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { Alert, AlertDescription } from '@/components/ui/alert'

export default function TaskCard({ task }) {
  const navigate = useNavigate()

  const getStatusBadge = (status) => {
    const variants = {
      pending: { bg: 'bg-yellow-100', text: 'text-yellow-800', icon: '⏳', label: 'Pendiente' },
      in_progress: { bg: 'bg-blue-100', text: 'text-blue-800', icon: '🔄', label: 'En Progreso' },
      completed: { bg: 'bg-green-100', text: 'text-green-800', icon: '✅', label: 'Completada' }
    }
    const variant = variants[status] || variants.pending
    
    return (
      <Badge className={`${variant.bg} ${variant.text} border-0`}>
        {variant.icon} {variant.label}
      </Badge>
    )
  }

  const handleViewDetail = () => {
    navigate(`/employee/task/${task.id}`)
  }

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="bg-gradient-to-r from-blue-50 to-purple-50">
        <div className="flex items-start justify-between">
          <CardTitle className="text-lg text-gray-900">{task.title}</CardTitle>
          {getStatusBadge(task.status)}
        </div>
      </CardHeader>
      <CardContent className="pt-4 space-y-3">
        <p className="text-sm text-gray-600 line-clamp-2">
          {task.description || 'Sin descripción'}
        </p>

        <div className="space-y-2">
          {task.schedule_date && (
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <Calendar className="h-4 w-4" />
              <span>{format(new Date(task.schedule_date), 'PPP', { locale: es })}</span>
            </div>
          )}

          <div className="flex items-center gap-2 text-sm text-gray-600">
            <Users className="h-4 w-4" />
            <span className="line-clamp-1">{task.assigned_names}</span>
          </div>

          {task.last_checkin && (
            <div className="flex items-center gap-2 text-sm text-green-600">
              <Clock className="h-4 w-4" />
              <span>Último fichaje: {format(new Date(task.last_checkin), 'PPp', { locale: es })}</span>
            </div>
          )}
        </div>

        {task.incident_description && (
          <Alert className="bg-red-50 border-red-200">
            <AlertCircle className="h-4 w-4 text-red-600" />
            <AlertDescription className="text-red-800 text-xs">
              <strong>Incidencia:</strong> {task.incident_description}
            </AlertDescription>
          </Alert>
        )}

        <Button
          onClick={handleViewDetail}
          className="w-full bg-blue-500 hover:bg-blue-600 text-white"
        >
          Ver Detalle
        </Button>
      </CardContent>
    </Card>
  )
}