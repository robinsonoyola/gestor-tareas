import { useLocation } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import { cn } from '@/lib/utils'
import {
  LayoutDashboard,
  ClipboardList,
  Users,
  QrCode,
  MapPin,
  BarChart3,
  CheckSquare,
  Settings
} from 'lucide-react'

export default function Sidebar() {
  const { userData } = useAuth()
  const location = useLocation()
  const isAdmin = userData?.is_admin

  // Para admin, solo mostramos Dashboard
  // Los tabs están dentro del AdminDashboard
  const adminLinks = [
    {
      name: 'Dashboard',
      href: '/admin',
      icon: LayoutDashboard
    }
  ]

  const employeeLinks = [
    {
      name: 'Mis Tareas',
      href: '/employee',
      icon: CheckSquare
    },
    {
      name: 'Configuración',
      href: '/employee/settings',
      icon: Settings
    }
  ]

  const links = isAdmin ? adminLinks : employeeLinks

  return (
    <aside className="hidden md:flex w-64 flex-col border-r bg-gray-50/40">
      <div className="flex-1 overflow-auto py-6 px-4">
        <nav className="space-y-1">
          {links.map((link) => {
            const isActive = location.pathname === link.href
            
            return (
              <a
                key={link.href}
                href={link.href}
                className={cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-all hover:bg-gray-100',
                  isActive
                    ? 'bg-blue-50 text-blue-700 hover:bg-blue-50'
                    : 'text-gray-700'
                )}
              >
                <link.icon className="h-5 w-5" />
                {link.name}
              </a>
            )
          })}
        </nav>
      </div>

      {/* Footer */}
      <div className="border-t p-4">
        <div className="flex items-center gap-3 rounded-lg bg-blue-50 p-3">
          <div className="flex-1">
            <p className="text-xs font-medium text-blue-900">
              {isAdmin ? '👑 Administrador' : '👷 Empleado'}
            </p>
            <p className="text-xs text-blue-700">
              {userData?.full_name}
            </p>
          </div>
        </div>
      </div>
    </aside>
  )
}