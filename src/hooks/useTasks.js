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

  return {
    tasks,
    loading,
    error,
    fetchTasks
  }
}
