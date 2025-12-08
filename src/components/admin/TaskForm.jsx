import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Checkbox } from '@/components/ui/checkbox'
import { Calendar } from '@/components/ui/calendar'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { cn } from '@/lib/utils'
import { CalendarIcon } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'

export default function TaskForm({ 
  open, 
  onClose, 
  onSubmit, 
  task = null, 
  employees = [] 
}) {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    status: 'pending',
    schedule_date: null,
    schedule_type: 'custom_date',
    schedule_interval: 1,
    schedule_days: '',
    assigned_users: []
  })

  useEffect(() => {
    if (task) {
      setFormData({
        title: task.title || '',
        description: task.description || '',
        status: task.status || 'pending',
        schedule_date: task.schedule_date ? new Date(task.schedule_date) : null,
        schedule_type: task.schedule_type || 'custom_date',
        schedule_interval: task.schedule_interval || 1,
        schedule_days: task.schedule_days || '',
        assigned_users: task.assigned_users?.map(u => u.id) || []
      })
    } else {
      setFormData({
        title: '',
        description: '',
        status: 'pending',
        schedule_date: null,
        schedule_type: 'custom_date',
        schedule_interval: 1,
        schedule_days: '',
        assigned_users: []
      })
    }
  }, [task, open])

  const handleSubmit = (e) => {
    e.preventDefault()
    console.log('📤 Enviando datos del formulario:', formData)
    onSubmit(formData)
  }

  const toggleEmployee = (employeeId) => {
    setFormData(prev => ({
      ...prev,
      assigned_users: prev.assigned_users.includes(employeeId)
        ? prev.assigned_users.filter(id => id !== employeeId)
        : [...prev.assigned_users, employeeId]
    }))
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-xl">
            {task ? '✏️ Editar Tarea' : '➕ Crear Nueva Tarea'}
          </DialogTitle>
          <DialogDescription>
            Completa los datos de la tarea
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Título */}
          <div className="space-y-2">
            <Label htmlFor="title" className="text-gray-900 font-semibold">Título *</Label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
              placeholder="Ej: Limpieza habitación 101"
              required
              className="border-gray-300"
            />
          </div>

          {/* Descripción */}
          <div className="space-y-2">
            <Label htmlFor="description" className="text-gray-900 font-semibold">Descripción</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              placeholder="Descripción detallada de la tarea..."
              rows={3}
              className="border-gray-300"
            />
          </div>

          {/* Estado */}
          <div className="space-y-2">
            <Label htmlFor="status" className="text-gray-900 font-semibold">Estado</Label>
            <Select
              value={formData.status}
              onValueChange={(value) => setFormData(prev => ({ ...prev, status: value }))}
            >
              <SelectTrigger className="border-gray-300">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="pending">⏳ Pendiente</SelectItem>
                <SelectItem value="in_progress">🔄 En Progreso</SelectItem>
                <SelectItem value="completed">✅ Completada</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Tipo de Programación */}
          <div className="space-y-2">
            <Label htmlFor="schedule_type" className="text-gray-900 font-semibold">Tipo de Programación</Label>
            <Select
              value={formData.schedule_type}
              onValueChange={(value) => setFormData(prev => ({ ...prev, schedule_type: value }))}
            >
              <SelectTrigger className="border-gray-300">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="custom_date">📅 Fecha Específica</SelectItem>
                <SelectItem value="daily">🔄 Tarea Diaria</SelectItem>
                <SelectItem value="weekly">📅 Tarea Semanal</SelectItem>
                <SelectItem value="monthly">📆 Tarea Mensual</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Fecha */}
          {formData.schedule_type === 'custom_date' && (
            <div className="space-y-2">
              <Label className="text-gray-900 font-semibold">Fecha Programada</Label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant="outline"
                    className={cn(
                      'w-full justify-start text-left font-normal border-gray-300',
                      !formData.schedule_date && 'text-muted-foreground'
                    )}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {formData.schedule_date ? (
                      format(formData.schedule_date, 'PPP', { locale: es })
                    ) : (
                      <span>Seleccionar fecha</span>
                    )}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0">
                  <Calendar
                    mode="single"
                    selected={formData.schedule_date}
                    onSelect={(date) => setFormData(prev => ({ ...prev, schedule_date: date }))}
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
            </div>
          )}

          {/* Intervalo para tareas recurrentes */}
          {['daily', 'weekly', 'monthly'].includes(formData.schedule_type) && (
            <div className="space-y-2">
              <Label htmlFor="interval" className="text-gray-900 font-semibold">
                Repetir cada {formData.schedule_type === 'daily' ? 'días' : formData.schedule_type === 'weekly' ? 'semanas' : 'meses'}
              </Label>
              <Input
                id="interval"
                type="number"
                min="1"
                value={formData.schedule_interval}
                onChange={(e) => setFormData(prev => ({ ...prev, schedule_interval: parseInt(e.target.value) || 1 }))}
                className="border-gray-300"
              />
            </div>
          )}

          {/* Empleados Asignados */}
          <div className="space-y-2">
            <Label className="text-gray-900 font-semibold">Asignar a empleados (selecciona uno o varios)</Label>
            <div className="border rounded-md p-4 max-h-48 overflow-y-auto space-y-2 border-gray-300 bg-gray-50">
              {employees.length === 0 ? (
                <p className="text-center text-gray-500 py-4">No hay empleados disponibles</p>
              ) : (
                employees.map((employee) => (
                  <div key={employee.id} className="flex items-center space-x-2 p-2 hover:bg-gray-100 rounded">
                    <Checkbox
                      id={employee.id}
                      checked={formData.assigned_users.includes(employee.id)}
                      onCheckedChange={() => toggleEmployee(employee.id)}
                    />
                    <label
                      htmlFor={employee.id}
                      className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 cursor-pointer text-gray-900 flex-1"
                    >
                      {employee.full_name}
                      {employee.is_admin && (
                        <span className="ml-2 text-xs text-blue-600 font-semibold">👑 Admin</span>
                      )}
                    </label>
                  </div>
                ))
              )}
            </div>
            <div className="bg-blue-50 border border-blue-200 rounded px-3 py-2">
              <p className="text-xs text-blue-800">
                <strong>{formData.assigned_users.length}</strong> empleado(s) seleccionado(s)
              </p>
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} className="bg-gray-100 text-gray-900 hover:bg-gray-200">
              Cancelar
            </Button>
            <Button type="submit" className="bg-blue-500 hover:bg-blue-600 text-white">
              💾 {task ? 'Guardar Cambios' : 'Crear Tarea'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}