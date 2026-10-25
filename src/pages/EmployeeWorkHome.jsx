import WorkSearch from '@/components/WorkSearch'
import {usabilityReady} from '@/lib/workFeatures'
import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import Layout from '@/components/layout/Layout'
import EmployeeDashboard from './EmployeeDashboard'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { LockKeyhole, ArrowRight, RefreshCw } from 'lucide-react'
import { getWorkMode, workRpc, elapsedSince } from '@/lib/workflow'

export default function EmployeeWorkHome() {
  const { userData } = useAuth()
  const navigate = useNavigate()
  const [searchParams,setSearchParams] = useSearchParams()
  const requestedFilter=searchParams.get('status') || 'all'
  const filter=requestedFilter==='in_progress'?'active':requestedFilter
  const setFilter=value=>setSearchParams(value==='all'?{}:{status:value==='active'?'in_progress':value})
  const [mode, setMode] = useState(null)
  const [day, setDay] = useState(null)
  const [error, setError] = useState('')
  const [, tick] = useState(0)
  const load = async () => {
    try {
      const enabled = await getWorkMode()
      setMode(enabled)
      if (enabled) setDay(await workRpc(await usabilityReady() ? 'work_my_day_v2' : 'work_my_day'))
      setError('')
    } catch (e) { setDay(null); setError(e.message) }
  }
  useEffect(() => {
    if (!userData?.id) return
    let cancelled = false
    const refresh = () => { if (!cancelled) load() }
    refresh()
    const interval = setInterval(refresh, 10000)
    window.addEventListener('focus', refresh)
    return () => { cancelled = true; clearInterval(interval); window.removeEventListener('focus', refresh) }
  }, [userData?.id])
  useEffect(() => { const timer = setInterval(() => tick(n => n + 1), 1000); return () => clearInterval(timer) }, [])
  if (mode === false && !error) return <EmployeeDashboard />
  const states = { pending: ['Pendiente', 'bg-amber-100 text-amber-800'], active: ['En curso', 'bg-blue-100 text-blue-800'], review: ['En revisión', 'bg-violet-100 text-violet-800'], completed: ['Completada', 'bg-green-100 text-green-800'], cancelled:['Cancelada','bg-slate-100 text-slate-800'], blocked:['Bloqueada por incidencia','bg-amber-100 text-amber-800'] }
  return <Layout><div className="max-w-5xl mx-auto space-y-6">
    <div className="flex items-center justify-between gap-3"><div><h1 className="text-3xl font-bold">Mis tareas del día</h1><p className="text-gray-500 mt-2">{userData?.full_name} · {day?.date || 'Cargando fecha…'}</p></div><Button variant="outline" onClick={load}><RefreshCw className="h-4 w-4" /> Actualizar</Button></div>
    <WorkSearch/>
    <p className="rounded-lg border bg-white p-4 text-gray-600">Se muestran las tareas de hoy y las pendientes de días anteriores. Puedes abrir únicamente tu tarea en curso. Para comenzar o finalizar, pasa tu tarjeta en la tablet y confirma la acción.</p>
    {error && <p role="alert" className="bg-red-50 text-red-800 p-4 rounded-lg">{error}</p>}
    {!day && !error && <p role="status">Cargando planificación…</p>}
    <div className="flex flex-wrap items-center gap-3"><label htmlFor="employee-task-filter" className="text-sm">Filtrar tareas</label><select id="employee-task-filter" className="min-w-0 border rounded-md bg-white p-2" value={filter} onChange={e=>setFilter(e.target.value)}><option value="all">Todas</option><option value="active">En curso</option><option value="pending">Pendientes</option><option value="review">En revisión</option><option value="completed">Completadas</option><option value="cancelled">Canceladas</option><option value="blocked">Bloqueadas por incidencia</option></select></div>
    {day?.items?.length === 0 && <Card><CardContent className="pt-6">No tienes tareas planificadas para hoy. Consulta al encargado.</CardContent></Card>}
    {day?.items?.length>0 && !day.items.some(item=>filter==='all'||item.state===filter) && <p role="status">No hay tareas con este filtro.</p>}
    {day?.items?.filter(item=>filter==='all'||item.state===filter).slice().sort((a,b)=>Number(b.state==='active')-Number(a.state==='active')).map(item => <Card key={item.id}><CardContent className="pt-6 flex flex-col sm:flex-row sm:items-center gap-4">
      <span className="text-gray-400 font-mono text-lg">{String(item.priority).padStart(2, '0')}</span>
      <div className="flex-1"><h2 className="font-semibold text-lg">{item.title}</h2><div className="flex gap-3 mt-2 items-center"><Badge className={states[item.state]?.[1]}>{states[item.state]?.[0]}</Badge>{item.overdue && <Badge className="bg-red-100 text-red-800">Atrasada</Badge>}{item.completed_late && <Badge className="bg-amber-100 text-amber-800">Finalizada fuera de plazo</Badge>}{item.state === 'active' && <span className="font-mono text-blue-700">{elapsedSince(item.started_at)}</span>}</div><p className="text-sm text-gray-500 mt-2">Fecha límite: {item.work_date}, al finalizar el día (Madrid).</p>{item.overdue && item.state==='pending' && <p className="text-sm text-red-700 mt-2">Pendiente de un día anterior. Consulta al encargado para reorganizarla.</p>}</div>
      {item.can_open ? <Button onClick={() => navigate(`/employee/task/${item.task_id}/work`)}>Abrir tarea <ArrowRight className="h-4 w-4" /></Button> : <span className="text-sm text-gray-500 flex gap-2 items-center"><LockKeyhole className="h-4 w-4" />{item.state === 'completed' ? 'Tarea finalizada' : item.state==='cancelled' ? 'Ejecución cancelada por el encargado' : item.state==='review' ? 'Esperando revisión del encargado' : item.state==='blocked' ? 'Bloqueada · consulta al encargado' : item.overdue ? 'Consulta al encargado' : 'Comienza en la tablet'}</span>}
    </CardContent></Card>)}
  </div></Layout>
}
