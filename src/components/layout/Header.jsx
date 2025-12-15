import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { 
  LogOut, 
  Settings, 
  User, 
  Building2, 
  Shield, 
  ChevronDown,
  Menu
} from 'lucide-react'
import { Badge } from '@/components/ui/badge'

export default function Header() {
  const { userData, signOut } = useAuth()
  const navigate = useNavigate()

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
    <header className="sticky top-0 z-50 w-full border-b bg-white shadow-sm">
      <div className="flex h-16 items-center justify-between px-4 md:px-6 lg:px-8">
        {/* Logo y Título */}
        <div className="flex items-center gap-3">
          <div className="flex items-center justify-center w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg shadow-sm">
            <Building2 className="h-6 w-6 text-white" />
          </div>
          <div className="hidden sm:block">
            <h1 className="text-lg md:text-xl font-bold text-gray-900 flex items-center gap-2">
              Hotel Tareas
              {userData?.is_admin && (
                <Badge className="bg-purple-100 text-purple-800 border-0 text-xs">
                  <Shield className="h-3 w-3 mr-1" />
                  Admin
                </Badge>
              )}
            </h1>
            <p className="text-xs text-gray-500 hidden md:block">
              {userData?.is_admin ? 'Panel de Administración' : 'Panel de Empleado'}
            </p>
          </div>
          {/* Solo icono en mobile */}
          <div className="sm:hidden">
            <h1 className="text-lg font-bold text-gray-900">HT</h1>
          </div>
        </div>

        {/* User Info y Menu */}
        <div className="flex items-center gap-2 md:gap-4">
          {/* User Info - Desktop */}
          <div className="hidden lg:block text-right">
            <p className="text-sm font-medium text-gray-900">{userData?.full_name}</p>
            <p className="text-xs text-gray-500">{userData?.email}</p>
          </div>

          {/* User Menu Dropdown */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <button 
                className="relative h-10 rounded-full hover:bg-gray-100 transition-colors flex items-center gap-2 px-2 md:px-3 border-0 bg-transparent cursor-pointer"
              >
                <Avatar className="h-8 w-8">
                  <AvatarFallback className="bg-gradient-to-br from-blue-500 to-blue-600 text-white text-sm font-semibold">
                    {getInitials(userData?.full_name)}
                  </AvatarFallback>
                </Avatar>
                <ChevronDown className="h-4 w-4 text-gray-500 hidden md:block" />
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
  )
}