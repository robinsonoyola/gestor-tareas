import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { formatDate, getStatusBadge } from '@/lib/utils'
import { Calendar, Clock, Users, Eye } from 'lucide-react'

export default function TaskCard({ task, onView }) {
  const statusInfo = getStatusBadge(task.status)
  
  const getStatusVariant = (status) => {
    const variants = {
      pending: 'warning',
      in_progress: 'default',
      completed: 'success'
    }
    return variants[status] || 'default'
  }

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader>
        <div className="flex justify-between items-start">
          <div className="flex-1">
            <CardTitle className="text-lg mb-2">{task.title}</CardTitle>
            <Badge variant={getStatusVariant(task.status)}>
              {statusInfo.label}
            </Badge>
          </div>
          <span className="text-sm text-muted-foreground">
            #{task.id.slice(0, 8)}
          </span>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Descripción */}
        {task.description && (
          <p className="text-sm text-muted-foreground line-clamp-2">
            {task.description}
          </p>
        )}

        {/* Info */}
        <div className="space-y-2 text-sm">
          <div className="flex items-center gap-2 text-muted-foreground">
            <Calendar className="h-4 w-4" />
            <span>{formatDate(task.schedule_date)}</span>
          </div>

          {task.assigned_names && (
            <div className="flex items-center gap-2 text-muted-foreground">
              <Users className="h-4 w-4" />
              <span className="line-clamp-1">{task.assigned_names}</span>
            </div>
          )}

          {task.last_checkin && (
            <div className="flex items-center gap-2 text-muted-foreground">
              <Clock className="h-4 w-4" />
              <span>Último fichaje: {new Date(task.last_checkin).toLocaleDateString()}</span>
            </div>
          )}
        </div>

        {/* Incidencia */}
        {task.incident_description && (
          <div className="bg-yellow-50 border-l-4 border-yellow-400 p-3 rounded">
            <p className="text-sm font-medium text-yellow-800">⚠️ Incidencia reportada</p>
            <p className="text-xs text-yellow-700 mt-1">{task.incident_description}</p>
          </div>
        )}

        {/* Botón Ver Detalle */}
        <Button 
          variant="outline" 
          className="w-full" 
          onClick={() => onView(task)}
        >
          <Eye className="mr-2 h-4 w-4" />
          Ver Detalle
        </Button>
      </CardContent>
    </Card>
  )
}