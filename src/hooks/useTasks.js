import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'

export function useTasks(userId = null) {
  const [tasks, setTasks] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetchTasks()
  }, [userId])

const fetchTasks = async () => {
  try {
    setLoading(true)
    
    let query = supabase
      .from('tasks')
      .select(`
        *,
        task_assignments!inner (
          user_id,
          users (
            id,
            full_name,
            email
          )
        )
      `)
      .order('created_at', { ascending: false })

    // Si es empleado, filtrar solo sus tareas
    if (userId) {
      query = query.eq('task_assignments.user_id', userId)
    }

    const { data, error } = await query

    if (error) throw error

    // Formatear datos - agrupar empleados por tarea
    const tasksMap = new Map()
    
    data.forEach(item => {
      const taskId = item.id
      
      if (!tasksMap.has(taskId)) {
        tasksMap.set(taskId, {
          ...item,
          task_assignments: [],
          assigned_users: [],
          assigned_names: ''
        })
      }
      
      const task = tasksMap.get(taskId)
      
      if (item.task_assignments && item.task_assignments.users) {
        task.task_assignments.push(item.task_assignments)
        task.assigned_users.push(item.task_assignments.users)
      }
    })
    
    // Convertir Map a Array y formatear nombres
    const formattedTasks = Array.from(tasksMap.values()).map(task => ({
      ...task,
      assigned_names: task.assigned_users
        .map(u => u.full_name)
        .filter((name, index, self) => self.indexOf(name) === index)
        .join(', ') || 'Sin asignar'
    }))

    console.log('✅ Tareas cargadas:', formattedTasks)
    setTasks(formattedTasks)
  } catch (error) {
    console.error('❌ Error fetching tasks:', error)
    setError(error.message)
  } finally {
    setLoading(false)
  }
}

const createTask = async (taskData) => {
  try {
    console.log('📝 Datos recibidos para crear tarea:', taskData)
    
    // Separar assigned_users del resto de datos
    const { assigned_users, ...taskFields } = taskData
    
    console.log('📋 Campos de tarea (sin assigned_users):', taskFields)
    console.log('👥 Usuarios a asignar:', assigned_users)

    // Crear tarea
    const { data: newTask, error: taskError } = await supabase
      .from('tasks')
      .insert([taskFields])
      .select()
      .single()

    if (taskError) {
      console.error('❌ Error al crear tarea:', taskError)
      throw taskError
    }

    console.log('✅ Tarea creada:', newTask)

    // Asignar empleados si se proporcionaron
    if (assigned_users && assigned_users.length > 0) {
      console.log('👥 Asignando empleados...')
      
      const assignments = assigned_users.map(userId => ({
        task_id: newTask.id,
        user_id: userId
      }))

      console.log('📝 Asignaciones a insertar:', assignments)

      const { error: assignError } = await supabase
        .from('task_assignments')
        .insert(assignments)

      if (assignError) {
        console.error('❌ Error al asignar empleados:', assignError)
        throw assignError
      }

      console.log('✅ Empleados asignados correctamente')
    }

    await fetchTasks()
    return { success: true, data: newTask }
  } catch (error) {
    console.error('❌ Error creating task:', error)
    return { success: false, error: error.message }
  }
}

  const updateTask = async (taskId, updates) => {
    try {
      const { error: updateError } = await supabase
        .from('tasks')
        .update(updates)
        .eq('id', taskId)

      if (updateError) throw updateError

      // Si se actualizaron los empleados asignados
      if (updates.assigned_users !== undefined) {
        // Eliminar asignaciones anteriores
        await supabase
          .from('task_assignments')
          .delete()
          .eq('task_id', taskId)

        // Crear nuevas asignaciones
        if (updates.assigned_users.length > 0) {
          const assignments = updates.assigned_users.map(userId => ({
            task_id: taskId,
            user_id: userId
          }))

          const { error: assignError } = await supabase
            .from('task_assignments')
            .insert(assignments)

          if (assignError) throw assignError
        }
      }

      await fetchTasks()
      return { success: true }
    } catch (error) {
      console.error('Error updating task:', error)
      return { success: false, error: error.message }
    }
  }

  const deleteTask = async (taskId) => {
    try {
      const { error } = await supabase
        .from('tasks')
        .delete()
        .eq('id', taskId)

      if (error) throw error

      await fetchTasks()
      return { success: true }
    } catch (error) {
      console.error('Error deleting task:', error)
      return { success: false, error: error.message }
    }
  }

  return {
    tasks,
    loading,
    error,
    fetchTasks,
    createTask,
    updateTask,
    deleteTask
  }
}