import { useAuth } from '@/hooks/useAuth'
import { useNavigate, useLocation } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { 
  LayoutDashboard, 
  Users, 
  ListTodo, 
  QrCode, 
  MapPin, 
  Key, 
  Settings,
  CreditCard,
  SlidersHorizontal,
  X,
  Building2,
  Shield
} from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

export default function Sidebar({ onClose }) {
  const { userData } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const handleNavigation = (path) => {
    navigate(path)
    if (onClose) onClose() // Cerrar sidebar en mobile
  }

  const isActive = (path) => {
    return location.pathname === path
  }

  const adminMenuItems = [
    {
      icon: LayoutDashboard,
      label: 'Dashboard',
      path: '/admin',
      badge: null
    },
    {
      icon: Users,
      label: 'Empleados',
      path: '/admin/employees',
      badge: null
    },
    {
      icon: QrCode,
      label: 'Códigos QR',
      path: '/admin/qr-generator',
      badge: null
    },
    {
      icon: MapPin,
      label: 'Ubicaciones GPS',
      path: '/admin/gps-locations',
      badge: null
    },
    {
      icon: Key,
      label: 'Accesos',
      path: '/admin/task-access-manager',
      badge: null
    },
    {
      icon: CreditCard,
      label: 'Tarjetas NFC',
      path: '/admin/nfc-cards',
      badge: 'Nuevo',
      badgeColor: 'bg-green-100 text-green-800'
    },
    {
      icon: SlidersHorizontal,
      label: 'Métodos Fichaje',
      path: '/admin/checkin-methods',
      badge: null
    }
  ]

  const employeeMenuItems = [
    {
      icon: LayoutDashboard,
      label: 'Mis Tareas',
      path: '/employee',
      badge: null
    },
    {
      icon: Settings,
      label: 'Configuración',
      path: '/employee/settings',
      badge: null
    }
  ]

  const menuItems = userData?.is_admin ? adminMenuItems : employeeMenuItems

  return (
    <aside className="w-64 bg-white border-r shadow-sm flex flex-col h-full">
      {/* Header con Logo */}
      <div className="p-4 border-b">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex items-center justify-center w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg shadow-sm">
              <Building2 className="h-6 w-6 text-white" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-gray-900">Hotel Tareas</h2>
              <p className="text-xs text-gray-500">
                {userData?.is_admin ? 'Admin' : 'Empleado'}
              </p>
            </div>
          </div>
          {/* Botón cerrar - solo mobile */}
          {onClose && (
            <Button
              variant="ghost"
              size="icon"
              onClick={onClose}
              className="lg:hidden"
            >
              <X className="h-5 w-5" />
            </Button>
          )}
        </div>

        {/* Badge de rol */}
        {userData?.is_admin && (
          <Badge className="bg-purple-100 text-purple-800 border-0 text-xs mt-3 w-full justify-center">
            <Shield className="h-3 w-3 mr-1" />
            Administrador
          </Badge>
        )}
      </div>

      {/* Navigation Menu */}
      <nav className="flex-1 overflow-y-auto p-4">
        <div className="space-y-1">
          {menuItems.map((item) => {
            const Icon = item.icon
            const active = isActive(item.path)

            return (
              <Button
                key={item.path}
                variant={active ? 'default' : 'ghost'}
                className={cn(
                  'w-full justify-start h-11 text-sm font-medium transition-colors',
                  active 
                    ? 'bg-blue-600 text-white hover:bg-blue-700' 
                    : 'text-gray-700 hover:bg-gray-100 hover:text-gray-900'
                )}
                onClick={() => handleNavigation(item.path)}
              >
                <Icon className={cn(
                  'mr-3 h-5 w-5',
                  active ? 'text-white' : 'text-gray-500'
                )} />
                <span className="flex-1 text-left">{item.label}</span>
                {item.badge && (
                  <Badge 
                    className={cn(
                      'ml-2 text-xs border-0',
                      item.badgeColor || 'bg-blue-100 text-blue-800'
                    )}
                  >
                    {item.badge}
                  </Badge>
                )}
              </Button>
            )
          })}
        </div>
      </nav>

      {/* Footer - User Info */}
      <div className="p-4 border-t bg-gray-50">
        <div className="flex items-center gap-3">
          <div className="flex items-center justify-center w-9 h-9 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full text-white text-sm font-semibold">
            {userData?.full_name?.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) || '?'}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-gray-900 truncate">
              {userData?.full_name}
            </p>
            <p className="text-xs text-gray-500 truncate">
              {userData?.email}
            </p>
          </div>
        </div>
      </div>
    </aside>
  )
}