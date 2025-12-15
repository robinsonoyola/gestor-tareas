import { useState } from 'react'
import { useAuth } from '@/hooks/useAuth'
import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  LogOut, 
  Building2, 
  Shield, 
  User, 
  Settings,
  Menu,
  X,
  ChevronDown
} from 'lucide-react'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import Sidebar from './Sidebar'

export default function Layout({ children }) {
  const { userData, signOut } = useAuth()
  const navigate = useNavigate()
  const [sidebarOpen, setSidebarOpen] = useState(false)

  const handleLogout = async () => {
    await signOut()
    navigate('/login')
  }

  const getInitials = (name) => {
    if (!name) return '?'
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2)
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="flex h-screen overflow-hidden">
        {/* Sidebar - Desktop */}
        <div className="hidden lg:block">
          <Sidebar />
        </div>

        {/* Sidebar - Mobile Overlay */}
        {sidebarOpen && (
          <>
            {/* Backdrop */}
            <div 
              className="fixed inset-0 bg-black/50 z-40 lg:hidden"
              onClick={() => setSidebarOpen(false)}
            />
            {/* Sidebar */}
            <div className="fixed inset-y-0 left-0 z-50 lg:hidden">
              <Sidebar onClose={() => setSidebarOpen(false)} />
            </div>
          </>
        )}
        
        {/* Main Content */}
        <main className="flex-1 overflow-auto">
          {/* Header */}
          <header className="sticky top-0 z-30 bg-white border-b shadow-sm">
            <div className="flex items-center justify-between px-4 py-3 md:px-6 md:py-4">
              {/* Left Section */}
              <div className="flex items-center gap-3">
                {/* Mobile Menu Button */}
                <Button
                  variant="ghost"
                  size="icon"
                  className="lg:hidden"
                  onClick={() => setSidebarOpen(true)}
                >
                  <Menu className="h-5 w-5" />
                </Button>

                {/* Logo */}
                <div className="flex items-center gap-3">
                  <div className="flex items-center justify-center w-9 h-9 md:w-10 md:h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg shadow-sm">
                    <Building2 className="h-5 w-5 md:h-6 md:w-6 text-white" />
                  </div>
                  <div className="hidden sm:block">
                    <h1 className="text-base md:text-lg font-bold text-gray-900 flex items-center gap-2">
                      Hotel Tareas
                      {userData?.is_admin && (
                        <Badge className="bg-purple-100 text-purple-800 border-0 text-xs hidden md:inline-flex">
                          <Shield className="h-3 w-3 mr-1" />
                          Admin
                        </Badge>
                      )}
                    </h1>
                    <p className="text-xs text-gray-500 hidden md:block">
                      {userData?.is_admin ? 'Panel de Administración' : 'Panel de Empleado'}
                    </p>
                  </div>
                </div>
              </div>

              {/* Right Section */}
              <div className="flex items-center gap-2 md:gap-4">
                {/* User Info - Desktop */}
                <div className="hidden md:block text-right">
                  <p className="text-sm font-medium text-gray-900">{userData?.full_name}</p>
                  <p className="text-xs text-gray-500">{userData?.email}</p>
                </div>

                {/* User Menu Dropdown */}
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <button 
                      className="relative h-10 rounded-full hover:bg-gray-100 transition-colors flex items-center gap-2 px-2 border-0 bg-transparent cursor-pointer"
                    >
                      <Avatar className="h-8 w-8">
                        <AvatarFallback className="bg-gradient-to-br from-blue-500 to-blue-600 text-white text-sm font-semibold">
                          {getInitials(userData?.full_name)}
                        </AvatarFallback>
                      </Avatar>
                      <ChevronDown className="h-4 w-4 text-gray-500 hidden sm:block" />
                    </button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent className="w-64" align="end" forceMount>
                    <DropdownMenuLabel>
                      <div className="flex flex-col space-y-1">
                        <p className="text-sm font-medium leading-none">{userData?.full_name}</p>
                        <p className="text-xs leading-none text-gray-500">
                          {userData?.email}
                        </p>
                        {userData?.is_admin && (
                          <Badge className="bg-purple-100 text-purple-800 border-0 text-xs mt-2 w-fit">
                            <Shield className="h-3 w-3 mr-1" />
                            Administrador
                          </Badge>
                        )}
                      </div>
                    </DropdownMenuLabel>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem 
                      onClick={() => navigate(userData?.is_admin ? '/admin' : '/employee')}
                      className="cursor-pointer"
                    >
                      <Building2 className="mr-2 h-4 w-4" />
                      <span>Dashboard</span>
                    </DropdownMenuItem>
                    <DropdownMenuItem 
                      onClick={() => navigate('/profile')}
                      className="cursor-pointer"
                    >
                      <User className="mr-2 h-4 w-4" />
                      <span>Mi Perfil</span>
                    </DropdownMenuItem>
                    <DropdownMenuItem 
                      onClick={() => navigate('/settings')}
                      className="cursor-pointer"
                    >
                      <Settings className="mr-2 h-4 w-4" />
                      <span>Configuración</span>
                    </DropdownMenuItem>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem 
                      onClick={handleLogout} 
                      className="text-red-600 cursor-pointer focus:text-red-600 focus:bg-red-50"
                    >
                      <LogOut className="mr-2 h-4 w-4" />
                      <span>Cerrar sesión</span>
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </div>
          </header>

          {/* Page Content */}
          <div className="p-4 md:p-6 lg:p-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}