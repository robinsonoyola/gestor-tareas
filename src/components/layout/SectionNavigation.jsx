import { NavLink, useLocation } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
const groups=[
 {prefix:'/admin/team',title:'Equipo',tabs:[['Empleados','/admin/team'],['Roles y autorizaciones','/admin/team/roles'],['Áreas y responsables','/admin/team/areas']]},
 {prefix:'/admin/access',title:'Accesos y credenciales',tabs:[['Enlaces y QR','/admin/access'],['Tarjetas personales','/admin/access/cards'],['Tarjetas asociadas a tareas','/admin/access/task-cards']]},
 {prefix:'/admin/checkins',title:'Fichajes',tabs:[['Registros','/admin/checkins','checkins.view'],['Puntos de fichaje','/admin/checkins/points','admin']]},
 {prefix:'/admin/settings',title:'Configuración',tabs:[['Ubicaciones GPS','/admin/settings'],['Reglas de fichaje','/admin/settings/methods'],['Modo tablet','/admin/settings/tablet']]}
]
export default function SectionNavigation(){const {pathname}=useLocation();const {can,isAdmin}=useAuth();const group=groups.find(g=>pathname===g.prefix||pathname.startsWith(g.prefix+'/'));if(!group)return null;return <div className="mb-6"><p className="text-xs uppercase tracking-wide text-gray-500 mb-3">{group.title}</p><nav aria-label={group.title} className="flex flex-wrap gap-2 border-b pb-3">{group.tabs.filter(([, ,permission])=>(!permission||permission==='admin')?isAdmin:can(permission)).map(([label,path])=><NavLink key={path} end to={path} className={({isActive})=>'px-4 py-2 rounded-lg text-sm font-medium '+(isActive?'bg-blue-600 text-white':'bg-white border text-gray-600 hover:bg-gray-50')}>{label}</NavLink>)}</nav></div>}
