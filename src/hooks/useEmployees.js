import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'

export function useEmployees() {
  const [employees, setEmployees] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetchEmployees()
  }, [])

  const fetchEmployees = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .order('full_name')

      if (error) throw error
      setEmployees(data)
    } catch (error) {
      console.error('Error fetching employees:', error)
      setError(error.message)
    } finally {
      setLoading(false)
    }
  }

  const createEmployee = async (employeeData) => {
    try {
      const { data, error } = await supabase
        .from('users')
        .insert([employeeData])
        .select()
        .single()

      if (error) throw error

      await fetchEmployees()
      return { success: true, data }
    } catch (error) {
      console.error('Error creating employee:', error)
      return { success: false, error: error.message }
    }
  }

  const updateEmployee = async (employeeId, updates) => {
    try {
      const { error } = await supabase
        .from('users')
        .update(updates)
        .eq('id', employeeId)

      if (error) throw error

      await fetchEmployees()
      return { success: true }
    } catch (error) {
      console.error('Error updating employee:', error)
      return { success: false, error: error.message }
    }
  }

  const deleteEmployee = async (employeeId) => {
    try {
      const { error } = await supabase
        .from('users')
        .delete()
        .eq('id', employeeId)

      if (error) throw error

      await fetchEmployees()
      return { success: true }
    } catch (error) {
      console.error('Error deleting employee:', error)
      return { success: false, error: error.message }
    }
  }

  return {
    employees,
    loading,
    error,
    fetchEmployees,
    createEmployee,
    updateEmployee,
    deleteEmployee
  }
}