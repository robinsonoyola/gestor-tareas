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
      setError(null)

      let query = supabase
        .from('tasks')
        .select(`
          *,
          task_assignments!task_assignments_task_id_fkey!inner (
            user_id,
            users (
              id,
              full_name,
              email
            )
          )
        `)
        .order('created_at', { ascending: false })

      if (userId) {
        query = query.eq('task_assignments.user_id', userId)
      }

      const { data, error } = await query

      if (error) throw error

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

        for (const assignment of item.task_assignments || []) {
          task.task_assignments.push(assignment)
          if (assignment.users) task.assigned_users.push(assignment.users)
        }
      })

      const formattedTasks = Array.from(tasksMap.values()).map(task => ({
        ...task,
        assigned_names: task.assigned_users
          .map(u => u.full_name)
          .filter((name, index, self) => self.indexOf(name) === index)
          .join(', ') || 'Sin asignar'
      }))

      setTasks(formattedTasks)
    } catch (error) {
      console.error('Error fetching tasks:', error)
      setError(error.message)
    } finally {
      setLoading(false)
    }
  }

  const createTask = async (taskData) => {
    try {
      console.log('📝 Datos recibidos para crear tarea:', taskData)

      const { assigned_users, ...taskFields } = taskData

      console.log('📋 Campos de tarea:', taskFields)
      console.log('👥 Usuarios a asignar:', assigned_users)

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

      if (assigned_users && assigned_users.length > 0) {
        console.log('👥 Asignando empleados...')

        const assignments = assigned_users.map(userId => ({
          task_id: newTask.id,
          user_id: userId
        }))

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
      const { assigned_users, ...taskFields } = updates

      const { error: updateError } = await supabase
        .from('tasks')
        .update(taskFields)
        .eq('id', taskId)

      if (updateError) throw updateError

      if (assigned_users !== undefined) {
        await supabase
          .from('task_assignments')
          .delete()
          .eq('task_id', taskId)

        if (assigned_users.length > 0) {
          const assignments = assigned_users.map(userId => ({
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
