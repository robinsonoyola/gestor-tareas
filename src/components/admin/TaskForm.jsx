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
        assigned_users: task.assigned_users?.map(u => u.id) || []
      })
    } else {
      setFormData({
        title: '',
        description: '',
        status: 'pending',
        schedule_date: null,
        schedule_type: 'custom_date',
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
          <DialogTitle>
            {task ? 'Editar Tarea' : 'Crear Nueva Tarea'}
          </DialogTitle>
          <DialogDescription>
            Completa los datos de la tarea
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Título */}
          <div className="space-y-2">
            <Label htmlFor="title">Título *</Label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
              placeholder="Ej: Limpieza habitación 101"
              required
            />
          </div>

          {/* Descripción */}
          <div className="space-y-2">
            <Label htmlFor="description">Descripción</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              placeholder="Descripción detallada de la tarea..."
              rows={3}
            />
          </div>

          {/* Estado */}
          <div className="space-y-2">
            <Label htmlFor="status">Estado</Label>
            <Select
              value={formData.status}
              onValueChange={(value) => setFormData(prev => ({ ...prev, status: value }))}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="pending">⏳ Pendiente</SelectItem>
                <SelectItem value="in_progress">🔄 En Progreso</SelectItem>
                <SelectItem value="completed">✅ Completada</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Fecha */}
          <div className="space-y-2">
            <Label>Fecha Programada</Label>
            <Popover>
              <PopoverTrigger asChild>
                <Button
                  variant="outline"
                  className={cn(
                    'w-full justify-start text-left font-normal',
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

          {/* Empleados Asignados */}
          <div className="space-y-2">
            <Label>Asignar a empleados</Label>
            <div className="border rounded-md p-4 max-h-48 overflow-y-auto space-y-2">
              {employees.map((employee) => (
                <div key={employee.id} className="flex items-center space-x-2">
                  <Checkbox
                    id={employee.id}
                    checked={formData.assigned_users.includes(employee.id)}
                    onCheckedChange={() => toggleEmployee(employee.id)}
                  />
                  <label
                    htmlFor={employee.id}
                    className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 cursor-pointer"
                  >
                    {employee.full_name}
                    {employee.is_admin && (
                      <span className="ml-2 text-xs text-blue-600">👑 Admin</span>
                    )}
                  </label>
                </div>
              ))}
            </div>
            <p className="text-xs text-muted-foreground">
              {formData.assigned_users.length} empleado(s) seleccionado(s)
            </p>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit">
              {task ? 'Guardar Cambios' : 'Crear Tarea'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}