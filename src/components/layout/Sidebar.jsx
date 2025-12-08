import { useLocation } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import { LayoutDashboard, CheckSquare, Settings, Key } from 'lucide-react'

export default function Sidebar() {
  const { userData } = useAuth()
  const location = useLocation()
  const isAdmin = userData?.is_admin

  const adminLinks = [
    { name: 'Dashboard', href: '/admin', icon: LayoutDashboard },
    { name: 'Códigos de Acceso', href: '/admin/task-access-manager', icon: Key }
  ]

  const employeeLinks = [
    { name: 'Mis Tareas', href: '/employee', icon: CheckSquare },
    { name: 'Configuración', href: '/employee/settings', icon: Settings }
  ]

  const links = isAdmin ? adminLinks : employeeLinks

  return (
    <aside className="w-64 flex-col border-r bg-gray-50 h-screen overflow-y-auto hidden md:flex">
      <div className="flex-1 py-6 px-4">
        <nav className="space-y-1">
          {links.map((link) => {
            const isActive = location.pathname === link.href
            const Icon = link.icon
            
            let classes = "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-all hover:bg-gray-100 text-gray-700"
            if (isActive) {
              classes = "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-all bg-blue-50 text-blue-700"
            }
            
            return (
              <a key={link.href} href={link.href} className={classes}>
                <Icon className="h-5 w-5" />
                <span className="truncate">{link.name}</span>
              </a>
            )
          })}
        </nav>
      </div>

      <div className="border-t p-4">
        <div className="flex items-center gap-3 rounded-lg bg-blue-50 p-3">
          <div className="flex-1 min-w-0">
            <p className="text-xs font-medium text-blue-900 truncate">
              {isAdmin ? '👑 Admin' : '👷 Empleado'}
            </p>
            <p className="text-xs text-blue-700 truncate">{userData?.full_name}</p>
          </div>
        </div>
      </div>
    </aside>
  )
}