import WorkSearch from '@/components/WorkSearch'
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import Layout from '@/components/layout/Layout'
import { useAuth } from '@/hooks/useAuth'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { workRpc, elapsedSince } from '@/lib/workflow'
import { AdminCharts } from './AdminDashboard'
export default function Overview(){
 const {can}=useAuth(),navigate=useNavigate();const [data,setData]=useState(null),[employees,setEmployees]=useState([]),[error,setError]=useState(''),[refresh,setRefresh]=useState(0)
 useEffect(()=>{
  let live=true
  const controller=new AbortController()
  const deadline=setTimeout(()=>{
   if(!live)return
   live=false
   controller.abort()
   setError('No se pudo cargar el inicio a tiempo. Comprueba la conexión y pulsa Actualizar para volver a intentarlo.')
  },15000)
  setError('')
  workRpc('work_home_summary',undefined,{signal:controller.signal}).then(d=>{
   if(live){clearTimeout(deadline);setData(d)}
  }).catch(e=>{
   if(live){clearTimeout(deadline);setError(e.message.includes('work_home_summary')?'No se pudo cargar el resumen del inicio. Pulsa Actualizar para volver a intentarlo.':e.message)}
  })
  if(can('reports.view'))workRpc('work_employee_directory',undefined,{signal:controller.signal}).then(d=>{if(live)setEmployees(d)}).catch(()=>{})
  const timer=setInterval(()=>{if(document.visibilityState==='visible')setRefresh(n=>n+1)},30000)
  return()=>{live=false;clearTimeout(deadline);clearInterval(timer);controller.abort()}
 },[refresh])
 const planPath=can('planning.view')?'/admin/planning':'/admin/productivity'
 return <Layout><div className="max-w-7xl mx-auto space-y-6"><div className="flex flex-wrap justify-between gap-3"><div><h1 className="text-3xl font-bold">Inicio</h1><p className="text-gray-500 mt-2">El trabajo de hoy y los asuntos que necesitan atención · {data?.date||(error?'Resumen no disponible':'Cargando…')}</p></div><Button variant="outline" onClick={()=>setRefresh(n=>n+1)}>Actualizar</Button></div>{error && <p role="alert" className="bg-red-50 text-red-800 rounded-lg p-4">{error}</p>}
 <WorkSearch/>
 {data && <><div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">{[['Planificadas hoy',data.counts.planned,planPath],['Completadas hoy',data.counts.completed,planPath],['En curso hoy',data.counts.active,planPath],['Atrasadas',data.overdue?.total,can('tasks.view')?'/admin/tasks?tab=overdue':'/admin/planning']].filter(([,value])=>value!=null).map(([label,value,path])=><button key={label} onClick={()=>navigate(path)} className="text-left border rounded-xl bg-white p-5 hover:border-blue-300"><p className="text-sm text-gray-500">{label}</p><p className="text-3xl font-semibold mt-2">{value}</p><p className="text-xs text-blue-700 mt-2">Consultar →</p></button>)}</div>
 {data.overdue && <Card><CardHeader><CardTitle>Tareas que requieren atención</CardTitle></CardHeader><CardContent className="space-y-3">{data.overdue.items.length===0 && <p className="text-gray-500">No hay tareas atrasadas.</p>}{data.overdue.items.map(t=><div key={t.id} className="border rounded-lg p-4 flex flex-wrap items-center justify-between gap-3"><div><p className="font-medium">{t.title}</p><p className="text-sm text-gray-500">{t.employee} · {t.work_date} · {t.state==='active'?'En curso fuera de plazo':'Pendiente'}</p></div><Button variant="outline" onClick={()=>navigate(can('planning.view')?`/admin/planning?employee=${t.user_id}&date=${t.work_date}`:'/admin/tasks?tab=overdue')}>Revisar</Button></div>)}{data.overdue.total>5 && <Button variant="outline" onClick={()=>navigate(can('tasks.view')?'/admin/tasks?tab=overdue':'/admin/planning')}>Ver seguimiento</Button>}</CardContent></Card>}
 {can('checkins.view') && <Card><CardHeader><CardTitle>Personas trabajando</CardTitle></CardHeader><CardContent className="space-y-3">{data.working.length===0 && <p className="text-gray-500">No hay fichajes abiertos.</p>}{data.working.map(c=><div key={c.id} className="flex flex-wrap gap-3 justify-between border rounded-lg p-3"><div><p className="font-medium">{c.employee||'Empleado eliminado'}</p><p className="text-sm text-gray-500">{c.title}</p></div><span className="text-blue-700 font-mono">{elapsedSince(c.checkin_time)}</span></div>)}<Button variant="outline" onClick={()=>navigate('/admin/checkins')}>Consultar fichajes</Button><p className="text-xs text-gray-500">Datos actualizados cada 30 segundos. Se muestran hasta 100 fichajes abiertos.</p></CardContent></Card>}
 </>}
 {can('reports.view') && <AdminCharts employees={employees} revision={refresh}/>}
 </div></Layout>
}
