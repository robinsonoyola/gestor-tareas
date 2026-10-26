import {useEffect,useMemo,useState} from 'react'
import Layout from '@/components/layout/Layout'
import {Card,CardContent,CardHeader,CardTitle} from '@/components/ui/card'
import {Button} from '@/components/ui/button'
import {CalendarDays,RefreshCw} from 'lucide-react'
import {workRpc} from '@/lib/workflow'

const labels={vacation:'Vacaciones',leave:'Permiso',sick:'Baja médica',unavailable:'No disponible'}
export default function EmployeeAbsences(){
 const [data,setData]=useState(null),[error,setError]=useState(''),[busy,setBusy]=useState(false)
 const load=async()=>{setBusy(true);setError('');try{setData(await workRpc('work_my_absences',{p_start:null,p_end:null}))}catch(e){setError(e.message.includes('work_my_absences')?'Falta activar la consulta personal de ausencias en ASE Work - Pruebas.':e.message)}finally{setBusy(false)}}
 useEffect(()=>{load()},[])
 const groups=useMemo(()=>{const result={current:[],upcoming:[],past:[]};for(const item of data?.items||[]){if(item.cancelled_at||item.end_date<data.today)result.past.push(item);else if(item.start_date<=data.today)result.current.push(item);else result.upcoming.push(item)}return result},[data])
 const list=(title,items,empty)=> <Card><CardHeader><CardTitle>{title}</CardTitle></CardHeader><CardContent className="space-y-3">{items.map(item=><div key={item.id} className={`rounded-xl border p-4 ${item.cancelled_at?'opacity-60':''}`}><div className="flex flex-wrap items-center justify-between gap-2"><p className="font-semibold">{labels[item.kind]||item.kind}</p><span className="text-sm">{item.start_date} — {item.end_date}</span></div>{item.note&&<p className="mt-2 whitespace-pre-wrap text-sm text-gray-500">{item.note}</p>}{item.cancelled_at&&<p className="mt-2 text-sm">Cancelada</p>}</div>)}{!items.length&&<p className="text-gray-500">{empty}</p>}</CardContent></Card>
 return <Layout><div className="mx-auto max-w-4xl space-y-6"><div className="flex flex-wrap items-start justify-between gap-3"><div><h1 className="text-3xl font-bold">Mis ausencias</h1><p className="mt-2 text-gray-500">Consulta tus vacaciones, permisos y períodos no disponibles registrados por la empresa.</p></div><Button variant="outline" disabled={busy} onClick={load}><RefreshCw className={`h-4 w-4 ${busy?'animate-spin':''}`}/>Actualizar</Button></div>{error&&<p role="alert" className="rounded-lg bg-red-50 p-4 text-red-800">{error}</p>}{!data&&!error&&<p role="status">Cargando tus períodos…</p>}{data&&<><div className="rounded-xl border bg-white p-4"><p className="flex items-center gap-2 font-medium"><CalendarDays className="h-5 w-5 text-blue-600"/>Esta pantalla es solo de consulta.</p><p className="mt-1 text-sm text-gray-500">Si necesitas solicitar o modificar un período, comunícalo al encargado.</p></div>{list('Ausencia actual',groups.current,'Ahora mismo no tienes una ausencia activa.')}{list('Próximas ausencias',groups.upcoming,'No tienes próximas ausencias registradas.')}{list('Historial',groups.past,'Todavía no hay períodos anteriores.')}</>}</div></Layout>
}
