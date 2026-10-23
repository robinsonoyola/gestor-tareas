import {useEffect,useState} from 'react'
import {supabase} from '@/lib/supabase'
const states={open:'Abierta',in_progress:'En atención',resolved:'Resuelta'}
export default function IncidentHistory({incidentId,updatedAt}){
 const [open,setOpen]=useState(false),[events,setEvents]=useState(null),[error,setError]=useState(''),[retry,setRetry]=useState(0)
 useEffect(()=>{
  if(!open)return
  let live=true;setError('');setEvents(null)
  supabase.rpc('work_incident_history',{p_incident:incidentId}).then(({data,error})=>{
   if(!live)return
   if(error){setError(['PGRST202','42883'].includes(error.code)?'Falta activar el historial de incidencias en Supabase.':'No se pudo cargar el historial.');return}
   setEvents(data||[])
  }).catch(()=>{if(live)setError('No se pudo cargar el historial.')})
  return()=>{live=false}
 },[open,incidentId,updatedAt,retry])
 return <details className="rounded-md border p-3 text-xs text-gray-600" onToggle={e=>setOpen(e.currentTarget.open)}>
  <summary className="cursor-pointer font-medium text-gray-700">Ver evolución de la incidencia</summary>
  {open&&<div className="mt-3 max-h-64 overflow-y-auto space-y-3" aria-live="polite">
   {error?<p role="alert">{error} <button className="underline" onClick={()=>setRetry(v=>v+1)}>Reintentar</button></p>:events===null?<p>Cargando historial…</p>:<>
    {events.length===0&&<p>No hay movimientos registrados.</p>}
    <ol className="border-l border-gray-200 ml-1 space-y-3">{events.map(event=><li key={event.id} className="pl-3 space-y-1">
     <p className="font-medium">{event.kind==='snapshot'?'Estado al activar el historial':event.kind==='created'?'Incidencia creada':event.previous_state!==event.state?`${states[event.previous_state]||event.previous_state} → ${states[event.state]||event.state}`:'Seguimiento actualizado'}{event.kind!=='updated'&&` · ${states[event.state]||event.state}`}</p>
     <p><time dateTime={event.at}>{new Date(event.at).toLocaleString('es-ES')}</time>{event.actor&&` · ${event.actor}`}</p>
     {event.note&&<p className="whitespace-pre-wrap break-words">{event.note}</p>}
    </li>)}</ol>
   </>}
  </div>}
 </details>
}
