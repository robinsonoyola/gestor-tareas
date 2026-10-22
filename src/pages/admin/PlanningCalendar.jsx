import {useEffect,useState} from 'react'
import {Card,CardContent,CardHeader,CardTitle} from '@/components/ui/card'
import {Button} from '@/components/ui/button'
import {workRpc,workDate} from '@/lib/workflow'
const iso=d=>d.toISOString().slice(0,10)
export default function PlanningCalendar({user,date,onSelect,revision}){
 const [mode,setMode]=useState('month'),[rows,setRows]=useState([]),[error,setError]=useState('')
 const selected=new Date((date||workDate())+'T12:00:00Z'),anchor=new Date(selected)
 if(mode==='month')anchor.setUTCDate(1)
 anchor.setUTCDate(anchor.getUTCDate()-((anchor.getUTCDay()+6)%7))
 const count=mode==='week'?7:42,start=iso(anchor),end=iso(new Date(anchor.getTime()+(count-1)*86400000))
 useEffect(()=>{let live=true;setRows([]);if(!user)return;workRpc('work_planning_calendar',{p_user:user,p_start:start,p_end:end}).then(d=>{if(live){setRows(d);setError('')}}).catch(()=>{if(live){setRows([]);setError('El calendario estará disponible al instalar 17-ORGANIZACION-Y-SEGUIMIENTO.sql.')}});return()=>{live=false}},[user,start,end,revision])
 return <PlanningCalendarView mode={mode} setMode={setMode} rows={rows} error={error} date={date} onSelect={onSelect}/>
}
export function PlanningCalendarView({mode='month',setMode=()=>{},rows=[],error='',date,onSelect}){
 const selected=new Date((date||workDate())+'T12:00:00Z'),anchor=new Date(selected)
 if(mode==='month')anchor.setUTCDate(1)
 anchor.setUTCDate(anchor.getUTCDate()-((anchor.getUTCDay()+6)%7))
 const count=mode==='week'?7:42,start=iso(anchor),end=iso(new Date(anchor.getTime()+(count-1)*86400000))
 const current=rows.find(r=>r.day===date)
 return <Card><CardHeader><div className="flex flex-wrap justify-between items-center gap-3"><CardTitle>Calendario del empleado</CardTitle><div className="flex gap-2"><Button variant={mode==='week'?'default':'outline'} onClick={()=>setMode('week')}>Semana</Button><Button variant={mode==='month'?'default':'outline'} onClick={()=>setMode('month')}>Mes</Button></div></div></CardHeader><CardContent>
 <p className="text-sm text-gray-500 mb-4">{selected.toLocaleDateString('es-ES',{month:'long',year:'numeric',timeZone:'UTC'})} · Pulsa una fecha para consultar su planificación.</p>
 {error && <p role="status" className="text-sm text-gray-500 mb-3">{error}</p>}
 <div className="grid grid-cols-7 gap-1 sm:gap-2 min-w-0" data-calendar-grid>
 {['L','M','X','J','V','S','D'].map((d,i)=><div key={i} className="text-center text-xs font-medium text-gray-500 py-2"><span className="sm:hidden">{d}</span><span className="hidden sm:inline">{['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'][i]}</span></div>)}
 {Array.from({length:count},(_,i)=>{const day=new Date(anchor.getTime()+i*86400000),value=iso(day),item=rows.find(r=>r.day===value);return <button type="button" key={value} onClick={()=>onSelect(value)} aria-label={`${value}: ${item?.total||0} tareas, ${item?.overdue||0} atrasadas, ${item?.completed||0} completadas`} aria-pressed={value===date} className={'min-w-0 h-20 sm:h-28 flex flex-col items-center sm:items-start justify-start gap-1 border rounded-lg p-1 sm:p-2 text-center sm:text-left hover:border-blue-400 '+(value===date?'border-blue-600 bg-blue-50':day.getUTCMonth()===selected.getUTCMonth()?'bg-white':'bg-gray-50 text-gray-400')}>
 <span className="font-semibold text-sm leading-5">{day.getUTCDate()}</span>
 <span className="text-xs leading-4 whitespace-nowrap">{item?.total||'—'}<span className="hidden md:inline">{item?' tareas':''}</span></span>
 <span className="flex gap-1 items-center min-h-2" aria-hidden="true">{Number(item?.overdue)>0&&<span className="w-1.5 h-1.5 shrink-0 rounded-full bg-red-500"/>}{Number(item?.completed)>0&&<span className="w-1.5 h-1.5 shrink-0 rounded-full bg-green-600"/>}</span>
 </button>})}
 </div>
 <div className="flex flex-wrap gap-x-4 gap-y-2 text-xs text-gray-500 mt-4"><span>El número inferior indica las tareas.</span><span className="flex items-center gap-1.5"><span className="w-2 h-2 rounded-full bg-red-500"/>Hay atrasadas</span><span className="flex items-center gap-1.5"><span className="w-2 h-2 rounded-full bg-green-600"/>Hay completadas</span></div>
 <div className="border rounded-lg bg-gray-50 p-3 mt-4 space-y-1" aria-live="polite"><p className="text-sm font-semibold">{selected.toLocaleDateString('es-ES',{weekday:'long',day:'numeric',month:'long',timeZone:'UTC'})}</p><p className="text-sm text-gray-600">{current?`${current.total} tareas · ${current.completed} completadas · ${current.active} en curso · ${current.overdue} atrasadas`:'Sin tareas guardadas para este día.'}</p></div>
 </CardContent></Card>
}
