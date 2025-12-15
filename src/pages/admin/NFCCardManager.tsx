import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import Layout from '@/components/layout/Layout'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { toast } from 'sonner'
import { CreditCard, Plus, Power, PowerOff, Trash2, Edit, Search, ArrowLeft } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

interface NFCCard {
  id: string
  card_uid: string
  card_name: string | null
  task_id: string | null
  is_active: boolean
  created_at: string
  assigned_at: string | null
  notes: string | null
  task?: {
    title: string
  }
}

interface Task {
  id: string
  title: string
}

export default function NFCCardManager() {
  const navigate = useNavigate()
  const [cards, setCards] = useState<NFCCard[]>([])
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false)
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false)
  const [selectedCard, setSelectedCard] = useState<NFCCard | null>(null)

  const [formData, setFormData] = useState({
    card_uid: '',
    card_name: '',
    task_id: '',
    notes: ''
  })

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)

      const { data: cardsData, error: cardsError } = await supabase
        .from('nfc_cards')
        .select(`
          *,
          task:tasks(title)
        `)
        .order('created_at', { ascending: false })

      if (cardsError) throw cardsError

      const { data: tasksData, error: tasksError } = await supabase
        .from('tasks')
        .select('id, title')
        .order('title')

      if (tasksError) throw tasksError

      setCards(cardsData || [])
      setTasks(tasksData || [])

    } catch (error) {
      console.error('Error:', error)
      toast.error('Error al cargar datos')
    } finally {
      setLoading(false)
    }
  }

  const handleCreateCard = async () => {
    try {
      if (!formData.card_uid.trim()) {
        toast.error('El UID de la tarjeta es obligatorio')
        return
      }

      const { error } = await supabase
        .from('nfc_cards')
        .insert({
          card_uid: formData.card_uid.trim(),
          card_name: formData.card_name.trim() || null,
          task_id: formData.task_id === 'none' ? null : formData.task_id,
          notes: formData.notes.trim() || null,
          assigned_at: formData.task_id ? new Date().toISOString() : null
        })

      if (error) throw error

      toast.success('✅ Tarjeta NFC creada')
      setIsCreateDialogOpen(false)
      resetForm()
      fetchData()

    } catch (error: any) {
      console.error('Error:', error)
      if (error.code === '23505') {
        toast.error('Esta tarjeta NFC ya está registrada')
      } else {
        toast.error('Error al crear tarjeta')
      }
    }
  }

  const handleUpdateCard = async () => {
    try {
      if (!selectedCard) return

      const { error } = await supabase
        .from('nfc_cards')
        .update({
          card_name: formData.card_name.trim() || null,
          task_id: formData.task_id === 'none' ? null : formData.task_id || null,
          notes: formData.notes.trim() || null,
          assigned_at: formData.task_id ? new Date().toISOString() : null
        })
        .eq('id', selectedCard.id)

      if (error) throw error

      toast.success('✅ Tarjeta actualizada')
      setIsEditDialogOpen(false)
      resetForm()
      fetchData()

    } catch (error) {
      console.error('Error:', error)
      toast.error('Error al actualizar tarjeta')
    }
  }

  const handleToggleActive = async (card: NFCCard) => {
    try {
      const { error } = await supabase
        .from('nfc_cards')
        .update({ is_active: !card.is_active })
        .eq('id', card.id)

      if (error) throw error

      toast.success(card.is_active ? 'Tarjeta desactivada' : 'Tarjeta activada')
      fetchData()

    } catch (error) {
      console.error('Error:', error)
      toast.error('Error al cambiar estado')
    }
  }

  const handleDeleteCard = async (cardId: string) => {
    if (!confirm('¿Estás seguro de eliminar esta tarjeta NFC?')) return

    try {
      const { error } = await supabase
        .from('nfc_cards')
        .delete()
        .eq('id', cardId)

      if (error) throw error

      toast.success('Tarjeta eliminada')
      fetchData()

    } catch (error) {
      console.error('Error:', error)
      toast.error('Error al eliminar tarjeta')
    }
  }

  const openEditDialog = (card: NFCCard) => {
    setSelectedCard(card)
    setFormData({
      card_uid: card.card_uid,
      card_name: card.card_name || '',
      task_id: card.task_id || '',
      notes: card.notes || ''
    })
    setIsEditDialogOpen(true)
  }

  const resetForm = () => {
    setFormData({
      card_uid: '',
      card_name: '',
      task_id: '',
      notes: ''
    })
    setSelectedCard(null)
  }

  const filteredCards = cards.filter(card =>
    card.card_uid.toLowerCase().includes(searchTerm.toLowerCase()) ||
    card.card_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    card.task?.title?.toLowerCase().includes(searchTerm.toLowerCase())
  )

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="text-center space-y-4">
            <div className="animate-spin rounded-full h-16 w-16 border-4 border-blue-600 border-t-transparent mx-auto"></div>
            <p className="text-gray-600 font-medium">Cargando tarjetas NFC...</p>
          </div>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="space-y-6 max-w-7xl mx-auto">
        {/* Header con navegación */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button
              variant="outline"
              size="icon"
              onClick={() => navigate('/admin')}
            >
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
              <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-3">
                <CreditCard className="h-8 w-8 text-blue-600" />
                Tarjetas NFC
              </h1>
              <p className="text-gray-600 mt-1">
                Gestiona las tarjetas NFC y asígnalas a tareas
              </p>
            </div>
          </div>

          <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
            <DialogTrigger asChild>
              <Button className="bg-blue-600 hover:bg-blue-700">
                <Plus className="mr-2 h-4 w-4" />
                Nueva Tarjeta
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Registrar Nueva Tarjeta NFC</DialogTitle>
                <DialogDescription>
                  Registra una tarjeta NFC y asígnala a una tarea
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4 mt-4">
                <div>
                  <Label htmlFor="card_uid">UID de la Tarjeta *</Label>
                  <Input
                    id="card_uid"
                    placeholder="Ej: 04:A1:B2:C3:D4:E5:F6"
                    value={formData.card_uid}
                    onChange={(e) => setFormData({ ...formData, card_uid: e.target.value })}
                  />
                  <p className="text-xs text-gray-500 mt-1">
                    El identificador único de la tarjeta NFC
                  </p>
                </div>

                <div>
                  <Label htmlFor="card_name">Nombre de la Tarjeta</Label>
                  <Input
                    id="card_name"
                    placeholder="Ej: Tarjeta Habitación 101"
                    value={formData.card_name}
                    onChange={(e) => setFormData({ ...formData, card_name: e.target.value })}
                  />
                </div>

                <div>
                  <Label htmlFor="task_id">Asignar a Tarea (opcional)</Label>
                  <Select value={formData.task_id} onValueChange={(value) => setFormData({ ...formData, task_id: value })}>
                    <SelectTrigger>
                      <SelectValue placeholder="Selecciona una tarea" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="none">Sin asignar</SelectItem>
                      {tasks.map(task => (
                        <SelectItem key={task.id} value={task.id}>
                          {task.title}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label htmlFor="notes">Notas</Label>
                  <Textarea
                    id="notes"
                    placeholder="Notas adicionales..."
                    value={formData.notes}
                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                    rows={3}
                  />
                </div>

                <div className="flex gap-2 pt-2">
                  <Button onClick={handleCreateCard} className="flex-1">
                    Crear Tarjeta
                  </Button>
                  <Button variant="outline" onClick={() => { setIsCreateDialogOpen(false); resetForm() }}>
                    Cancelar
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card className="border-2">
            <CardContent className="pt-6">
              <div className="text-3xl font-bold text-gray-900">{cards.length}</div>
              <p className="text-sm text-gray-600 mt-1 font-medium">Total Tarjetas</p>
            </CardContent>
          </Card>
          <Card className="border-2 border-green-200 bg-green-50">
            <CardContent className="pt-6">
              <div className="text-3xl font-bold text-green-600">
                {cards.filter(c => c.is_active).length}
              </div>
              <p className="text-sm text-green-700 mt-1 font-medium">Activas</p>
            </CardContent>
          </Card>
          <Card className="border-2 border-blue-200 bg-blue-50">
            <CardContent className="pt-6">
              <div className="text-3xl font-bold text-blue-600">
                {cards.filter(c => c.task_id).length}
              </div>
              <p className="text-sm text-blue-700 mt-1 font-medium">Asignadas</p>
            </CardContent>
          </Card>
          <Card className="border-2 border-gray-200 bg-gray-50">
            <CardContent className="pt-6">
              <div className="text-3xl font-bold text-gray-600">
                {cards.filter(c => !c.task_id).length}
              </div>
              <p className="text-sm text-gray-700 mt-1 font-medium">Sin Asignar</p>
            </CardContent>
          </Card>
        </div>

        {/* Search */}
        <div className="flex items-center gap-2">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <Input
              placeholder="Buscar por UID, nombre o tarea..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
          </div>
        </div>

        {/* Cards List */}
        <div className="space-y-4">
          {filteredCards.map(card => (
            <Card key={card.id} className="border-2 hover:shadow-md transition-shadow">
              <CardContent className="p-6">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <CreditCard className="h-5 w-5 text-blue-600" />
                      <h3 className="font-semibold text-lg">
                        {card.card_name || 'Tarjeta sin nombre'}
                      </h3>
                      <Badge variant={card.is_active ? 'default' : 'secondary'}>
                        {card.is_active ? 'Activa' : 'Inactiva'}
                      </Badge>
                      {card.task_id && (
                        <Badge variant="outline" className="bg-blue-100 text-blue-800 border-blue-200 border">
                          Asignada
                        </Badge>
                      )}
                    </div>

                    <div className="space-y-1 text-sm text-gray-600">
                      <p><strong>UID:</strong> {card.card_uid}</p>
                      {card.task && (
                        <p><strong>Tarea:</strong> {card.task.title}</p>
                      )}
                      {card.notes && (
                        <p><strong>Notas:</strong> {card.notes}</p>
                      )}
                      <p className="text-xs">
                        Creada: {new Date(card.created_at).toLocaleDateString('es-ES')}
                        {card.assigned_at && ` • Asignada: ${new Date(card.assigned_at).toLocaleDateString('es-ES')}`}
                      </p>
                    </div>
                  </div>

                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleToggleActive(card)}
                    >
                      {card.is_active ? (
                        <><PowerOff className="h-4 w-4 mr-1" /> Desactivar</>
                      ) : (
                        <><Power className="h-4 w-4 mr-1" /> Activar</>
                      )}
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => openEditDialog(card)}
                    >
                      <Edit className="h-4 w-4 mr-1" /> Editar
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleDeleteCard(card.id)}
                      className="text-red-600 hover:text-red-700 hover:bg-red-50"
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {filteredCards.length === 0 && (
          <Card className="border-2 border-dashed">
            <CardContent className="text-center py-12">
              <CreditCard className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-600 font-medium">
                {searchTerm ? 'No se encontraron tarjetas' : 'No hay tarjetas NFC registradas'}
              </p>
              {!searchTerm && (
                <Button
                  className="mt-4"
                  onClick={() => setIsCreateDialogOpen(true)}
                >
                  <Plus className="mr-2 h-4 w-4" />
                  Registrar Primera Tarjeta
                </Button>
              )}
            </CardContent>
          </Card>
        )}

        {/* Edit Dialog */}
        <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Editar Tarjeta NFC</DialogTitle>
              <DialogDescription>
                Modifica la información de la tarjeta
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 mt-4">
              <div>
                <Label>UID de la Tarjeta</Label>
                <Input value={formData.card_uid} disabled className="bg-gray-100" />
                <p className="text-xs text-gray-500 mt-1">El UID no se puede modificar</p>
              </div>

              <div>
                <Label htmlFor="edit_card_name">Nombre de la Tarjeta</Label>
                <Input
                  id="edit_card_name"
                  placeholder="Ej: Tarjeta Habitación 101"
                  value={formData.card_name}
                  onChange={(e) => setFormData({ ...formData, card_name: e.target.value })}
                />
              </div>

              <div>
                <Label htmlFor="edit_task_id">Asignar a Tarea</Label>
                <Select value={formData.task_id} onValueChange={(value) => setFormData({ ...formData, task_id: value })}>
                  <SelectTrigger>
                    <SelectValue placeholder="Selecciona una tarea" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="none">Sin asignar</SelectItem>
                    {tasks.map(task => (
                      <SelectItem key={task.id} value={task.id}>
                        {task.title}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label htmlFor="edit_notes">Notas</Label>
                <Textarea
                  id="edit_notes"
                  placeholder="Notas adicionales..."
                  value={formData.notes}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                  rows={3}
                />
              </div>

              <div className="flex gap-2 pt-2">
                <Button onClick={handleUpdateCard} className="flex-1">
                  Guardar Cambios
                </Button>
                <Button variant="outline" onClick={() => { setIsEditDialogOpen(false); resetForm() }}>
                  Cancelar
                </Button>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      </div>
    </Layout>
  )
}