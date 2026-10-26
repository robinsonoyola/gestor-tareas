import {useEffect,useState} from 'react'
import {useNavigate} from 'react-router-dom'
import {ArrowRight,Clock3,Play,RefreshCw} from 'lucide-react'
import Layout from '@/components/layout/Layout'
import {Button} from '@/components/ui/button'
import {Badge} from '@/components/ui/badge'
import {Card,CardContent} from '@/components/ui/card'
import {useAuth} from '@/hooks/useAuth'
import {workRpc} from '@/lib/workflow'

const stateLabels={pending:'Lista para comenzar',active:'En curso',paused:'Pausada'}
const stateColors={pending:'bg-amber-100 text-amber-800',active:'bg-blue-100 text-blue-800',paused:'bg-orange-100 text-orange-800'}

export default function EmployeeCurrentWork(){
 const {userData}=useAuth(),navigate=useNavigate()
 const [data,setData]=useState(null),[error,setError]=useState(''),[busy,setBusy]=useState(false)
 const load=async()=>{setBusy(true);try{setData(await workRpc('work_mobile_queue'));setError('')}catch(e){setError(e.message)}finally{setBusy(false)}}
 useEffect(()=>{let live=true;const refresh=()=>live&&load();refresh();const timer=setInterval(refresh,10000);window.addEventListener('focus',refresh);return()=>{live=false;clearInterval(timer);window.removeEventListener('focus',refresh)}},[userData?.id])
 const items=data?.items||[]
 const current=items.find(item=>item.state==='active')||items.find(item=>item.state==='paused')||items.find(item=>item.plan_id===data?.next_plan&&item.can_start)
 const open=()=>current&&navigate(`/employee/task/${current.task_id}/work?plan=${current.plan_id}`)
 return <Layout><div className="mx-auto max-w-3xl space-y-6"><div className="flex flex-wrap items-center justify-between gap-3"><div><h1 className="text-3xl font-bold">Trabajo actual</h1><p className="mt-2 text-gray-500">{userData?.full_name} · {data?.date||'Cargando fecha…'}</p></div><Button variant="outline" disabled={busy} onClick={load}><RefreshCw className={`h-4 w-4 ${busy?'animate-spin':''}`}/>Actualizar</Button></div>
 <p className="rounded-lg border bg-white p-4 text-gray-600">Aquí aparece únicamente la tarea que corresponde ejecutar ahora. ASE Work respeta el orden fijado por el encargado; la importancia no adelanta otras tareas.</p>
 {error&&<p role="alert" className="rounded-lg bg-red-50 p-4 text-red-800">{error}</p>}
 {!data&&!error&&<p role="status">Comprobando tu trabajo actual…</p>}
 {data&&!current&&<Card><CardContent className="py-10 text-center"><Clock3 className="mx-auto mb-4 h-10 w-10 text-muted-foreground"/><h2 className="text-xl font-semibold">No tienes una tarea disponible ahora</h2><p className="mt-2 text-gray-500">Cuando el encargado planifique o habilite la siguiente tarea, aparecerá aquí automáticamente.</p></CardContent></Card>}
 {current&&<Card className="overflow-hidden border-2 border-blue-500/40 shadow-lg"><div className="h-1.5 bg-gradient-to-r from-blue-600 to-violet-600"/><CardContent className="space-y-5 p-5 sm:p-7"><div className="flex flex-wrap items-start justify-between gap-3"><div className="min-w-0"><p className="text-sm font-medium text-blue-600">Tarea que corresponde ahora</p><h2 className="mt-1 break-words text-2xl font-bold">{current.title}</h2></div><div className="flex flex-wrap gap-2"><Badge className={stateColors[current.state]}>{stateLabels[current.state]}</Badge>{current.importance==='urgent'&&<Badge className="bg-red-600 text-white">Urgente</Badge>}</div></div><dl className="grid gap-3 rounded-lg border bg-muted/30 p-4 sm:grid-cols-2"><div><dt className="text-xs text-muted-foreground">Orden</dt><dd className="font-medium">{current.priority??'—'}</dd></div><div><dt className="text-xs text-muted-foreground">Fecha planificada</dt><dd className="font-medium">{current.work_date||'—'}</dd></div></dl><Button size="lg" className="w-full" onClick={open}>{current.state==='active'?'Continuar trabajo':current.state==='paused'?'Reanudar trabajo':'Comenzar proceso de fichaje'}{current.state==='pending'?<Play className="h-5 w-5"/>:<ArrowRight className="h-5 w-5"/>}</Button><p className="text-center text-xs text-muted-foreground">La siguiente pantalla comprobará el método de fichaje permitido y volverá a validar el orden.</p></CardContent></Card>}
 </div></Layout>
}
