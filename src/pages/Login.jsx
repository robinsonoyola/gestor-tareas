import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import LoginForm from '@/components/auth/LoginForm'

export default function Login() {
  const navigate = useNavigate()
  const { user, userData, loading } = useAuth()

  useEffect(() => {
    if (user && userData) {
      if (userData.is_admin) {
        navigate('/admin')
      } else {
        navigate('/employee')
      }
    }
  }, [user, userData, navigate])

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gradient-to-br from-blue-400 to-cyan-400">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-white mx-auto"></div>
          <p className="mt-4 text-white">Verificando sesión...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex items-center justify-center min-h-screen bg-gradient-to-br from-blue-400 to-cyan-400 p-4">
      <LoginForm />
    </div>
  )
}