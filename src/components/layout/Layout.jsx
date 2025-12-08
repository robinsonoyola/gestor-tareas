import { useAuth } from '@/hooks/useAuth'
import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { LogOut } from 'lucide-react'
import Sidebar from './Sidebar'

export default function Layout({ children }) {
const { userData, signOut } = useAuth()
  const navigate = useNavigate()

  const handleLogout = async () => {
    await signOut()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="flex">
        <Sidebar />
        
        <main className="flex-1 overflow-auto">
          <header className="bg-white border-b px-6 py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <h1 className="text-xl font-bold text-gray-900">🏨 Hotel Tareas</h1>
                <span className="text-sm text-gray-600">
                  Panel de {userData?.is_admin ? 'Administración' : 'Empleado'}
                </span>
              </div>
              <div className="flex items-center gap-4">
                <div className="text-right">
                  <p className="text-sm font-medium text-gray-900">{userData?.full_name}</p>
                  <p className="text-xs text-gray-600">{userData?.email}</p>
                </div>
                <Button
                  onClick={handleLogout}
                  variant="outline"
                  size="sm"
                  className="text-red-600 hover:text-red-700 hover:bg-red-50"
                >
                  <LogOut className="mr-2 h-4 w-4" />
                  Salir
                </Button>
              </div>
            </div>
          </header>

          <div className="p-4 md:p-6 lg:p-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}