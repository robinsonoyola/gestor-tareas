import { useAuth } from '@/hooks/useAuth'
import { useNavigate, useLocation } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import {
  LayoutDashboard,
  Clock,
  CalendarDays,
  Users,
  ListTodo,
  BarChart3,
  QrCode,
  MapPin,
  Key,
  Settings,
  CreditCard,
  SlidersHorizontal,
  X,
  Shield,
  BriefcaseBusiness
} from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

export default function Sidebar({ onClose }) {
  const { userData, can, roleName } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const handleNavigation = (path) => {
    navigate(path)
    if (onClose) onClose() // Cerrar sidebar en mobile
  }

  const isActive = (path) => {
    if (path==='/admin/reports' && location.pathname==='/admin/productivity') return true
    const [pathname,query] = path.split('?')
    if (query) return location.pathname===pathname && new URLSearchParams(location.search).get('status')===new URLSearchParams(query).get('status')
    if (pathname==='/employee') return location.pathname===pathname && !['pending','in_progress','completed'].includes(new URLSearchParams(location.search).get('status'))
    return location.pathname === pathname || (pathname !== '/admin' && location.pathname.startsWith(pathname+'/'))
  }

  const adminMenuItems = [
    {icon:LayoutDashboard,label:'Inicio',path:'/admin',any:['tasks.view','planning.view','reports.view','checkins.view']},
    {icon:ListTodo,label:'Tareas',path:'/admin/tasks',permission:'tasks.view'},
    {icon:CalendarDays,label:'Planificación',path:'/admin/planning',permission:'planning.view'},
    {icon:Clock,label:'Fichajes',path:'/admin/checkins',permission:'checkins.view'},
    {icon:BarChart3,label:'Informes y análisis',path:'/admin/reports',permission:'reports.view'},
    {icon:Clock,label:'Incidencias',path:'/incidents',permission:'incidents.view'},
    {icon:Users,label:'Equipo',path:'/admin/team'},
    {icon:Key,label:'Accesos y credenciales',path:'/admin/access'},
    {icon:Settings,label:'Configuración',path:'/admin/settings'}
  ]

  const employeeMenuItems = [
    {
      icon: LayoutDashboard,
      label: 'Mis Tareas',
      path: '/employee',
      badge: null
    },
    {icon:ListTodo,label:'Pendientes',path:'/employee?status=pending',badge:null},
    {icon:Clock,label:'En progreso',path:'/employee?status=in_progress',badge:null},
    {icon:ListTodo,label:'Completadas',path:'/employee?status=completed',badge:null},
    {icon:Clock,label:'Incidencias',path:'/incidents',badge:null},
    {icon:Clock,label:'Mi historial',path:'/employee/history',badge:null},
    {
      icon: Settings,
      label: 'Mi cuenta',
      path: '/employee/settings',
      badge: null
    }
  ]

  const menuItems = userData?.is_admin ? adminMenuItems : [...adminMenuItems.filter(item=>(item.permission && can(item.permission)) || item.any?.some(can)),...employeeMenuItems]

  return (
    <aside className="ase-sidebar w-64 text-[#F8FAFC] border-r border-white/10 flex flex-col h-full">
      {/* Header con Logo */}
      <div className="p-4 border-b border-white/10">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="ase-brand-tile flex items-center justify-center w-10 h-10 shrink-0 rounded-xl shadow-sm">
              <img src="/ase-icon.svg" alt="" aria-hidden="true" className="w-10 h-10 rounded-lg" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-50">ASE Work</h2>
              <p className="text-xs text-slate-400">
                {userData?.is_admin ? 'Admin' : roleName || 'Empleado'}
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
          <Badge className="bg-white/10 text-slate-300 border-0 text-xs mt-3 w-full justify-center">
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
                    : 'text-slate-300 hover:bg-white/10 hover:text-white'
                )}
                onClick={() => handleNavigation(item.path)}
              >
                <Icon className={cn(
                  'mr-3 h-5 w-5',
                  active ? 'text-white' : 'text-slate-400'
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
      <div className="ase-sidebar-footer p-4 border-t border-white/10">
        <div className="flex items-center gap-3">
          <div className="flex items-center justify-center w-9 h-9 bg-blue-600 rounded-full text-white text-sm font-semibold">
            {userData?.full_name?.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) || '?'}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-slate-50 truncate">
              {userData?.full_name}
            </p>
            <p className="text-xs text-slate-400 truncate">
              {userData?.email}
            </p>
          </div>
        </div>
      </div>
    </aside>
  )
}
