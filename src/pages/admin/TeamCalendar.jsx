import {useEffect,useMemo,useState} from 'react'
import {Link,useNavigate} from 'react-router-dom'
import Layout from '@/components/layout/Layout'
import {Card,CardContent} from '@/components/ui/card'
import {Button} from '@/components/ui/button'
import {Input} from '@/components/ui/input'
import {Label} from '@/components/ui/label'
import {ChevronLeft,ChevronRight,RefreshCw} from 'lucide-react'
import {sectionTabClass,sectionTabsClass} from '@/components/ui/section-tabs'
import {workDate,workRpc} from '@/lib/workflow'

const iso=date=>date.toISOString().slice(0,10)
const monday=value=>{const date=new Date(value+'T12:00:00Z');date.setUTCDate(date.getUTCDate()-((date.getUTCDay()+6)%7));return iso(date)}
const add=(value,days)=>{const date=new Date(value+'T12:00:00Z');date.setUTCDate(date.getUTCDate()+days);return iso(date)}
const label=value=>new Date(value+'T12:00:00Z').toLocaleDateString('es-ES',{weekday:'short',day:'numeric',month:'short',timeZone:'UTC'})

export default function TeamCalendar(){
 const navigate=useNavigate(),[start,setStart]=useState(()=>monday(workDate())),[area,setArea]=useState(''),[search,setSearch]=useState(''),[data,setData]=useState(null),[error,setError]=useState(''),[busy,setBusy]=useState(false),end=add(start,6)
 const load=async()=>{setBusy(true);setError('');try{setData(await workRpc('work_team_calendar',{p_start:start,p_end:end,p_area:area||null}))}catch(e){setError(e.message.includes('work_team_calendar')?'Falta activar el calendario conjunto en ASE Work - Pruebas.':e.message)}finally{setBusy(false)}}
 useEffect(()=>{load()},[start,area])
 const days=useMemo(()=>Array.from({length:7},(_,index)=>add(start,index)),[start])
 const people=(data?.employees||[]).filter(person=>person.full_name.toLocaleLowerCase('es').includes(search.toLocaleLowerCase('es')))
 const open=(person,date)=>navigate(`/admin/planning?employee=${person.id}&date=${date}`)
 return <Layout><div className="mx-auto max-w-7xl space-y-6"><div><h1 className="text-3xl font-bold">Calendario del equipo</h1><p className="mt-2 text-gray-500">Consulta conjuntamente la carga diaria y la disponibilidad. La edición continúa en la planificación individual.</p></div>
 <div className={sectionTabsClass}><Button variant="outline" className={sectionTabClass(false)} asChild><Link to="/admin/planning">Planificación</Link></Button><Button variant="outline" className={sectionTabClass(false)} asChild><Link to={`/admin/planning/board?date=${start}`}>Tablero</Link></Button><Button variant="outline" className={sectionTabClass(true)} aria-current="page">Calendario equipo</Button><Button variant="outline" className={sectionTabClass(false)} asChild><Link to="/admin/planning/recurrences">Repeticiones</Link></Button></div>
 {error&&<p role="alert" className="rounded-lg bg-red-50 p-4 text-red-800">{error}</p>}
 <Card><CardContent className="grid gap-4 pt-6 md:grid-cols-3"><div><Label htmlFor="team-calendar-search">Buscar empleado</Label><Input id="team-calendar-search" value={search} onChange={e=>setSearch(e.target.value)} placeholder="Nombre del empleado"/></div><div><Label htmlFor="team-calendar-area">Área</Label><select id="team-calendar-area" className="w-full rounded-md border bg-white p-2" value={area} onChange={e=>setArea(e.target.value)}><option value="">Todas las áreas</option>{data?.areas?.map(item=><option key={item.id} value={item.id}>{item.name}</option>)}</select></div><div className="flex items-end gap-2"><Button variant="outline" aria-label="Semana anterior" onClick={()=>setStart(add(start,-7))}><ChevronLeft/></Button><Button variant="outline" className="flex-1" onClick={()=>setStart(monday(workDate()))}>Semana actual</Button><Button variant="outline" aria-label="Semana siguiente" onClick={()=>setStart(add(start,7))}><ChevronRight/></Button><Button variant="outline" aria-label="Actualizar" disabled={busy} onClick={load}><RefreshCw className={busy?'animate-spin':''}/></Button></div></CardContent></Card>
 <p className="text-sm text-gray-500">Semana del {start} al {end}. Pulsa un día para revisar la planificación de esa persona.</p>
 <div className="space-y-4">{people.map(person=><Card key={person.id}><CardContent className="pt-6"><h2 className="mb-4 font-semibold">{person.full_name}</h2><div className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-7">{days.map(day=>{const item=person.days.find(value=>value.date===day)||{total:0,active:0,paused:0,blocked:0};return <button type="button" key={day} onClick={()=>open(person,day)} className={`min-h-28 rounded-xl border p-3 text-left transition hover:border-blue-400 ${item.absent?'border-amber-300 bg-amber-50 text-amber-950':'bg-white'}`}><span className="block text-xs font-semibold capitalize">{label(day)}</span>{item.absent&&<span className="mt-2 block text-xs font-bold text-amber-800">Ausente</span>}<span className="mt-2 block text-lg font-bold">{item.total}</span><span className="block text-xs">tareas</span>{item.active+item.paused>0&&<span className="mt-1 block text-xs text-blue-700">{item.active+item.paused} en curso/pausa</span>}{item.blocked>0&&<span className="block text-xs text-red-700">{item.blocked} bloqueadas</span>}</button>})}</div></CardContent></Card>)}{data&&!people.length&&<p className="rounded-xl border bg-white p-6 text-center">No hay empleados con estos filtros.</p>}</div>
 </div></Layout>
}
