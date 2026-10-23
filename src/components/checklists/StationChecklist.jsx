import {useEffect,useState} from 'react'
import {stationRpc} from '@/lib/workflow'
import {Button} from '@/components/ui/button'
export default function StationChecklist({station,ticket,onInteract}) {
 const [open,setOpen]=useState(false),[steps,setSteps]=useState([]),[busy,setBusy]=useState(false),[error,setError]=useState('')
 const load=async(step=null,done=null)=>{if(busy)return;setBusy(true);setError('');onInteract();try{const data=await stationRpc('work_station_checklist',{p_station:station,p_ticket:ticket,p_step:step,p_done:done});setSteps(data.steps);setOpen(true)}catch(e){setError(e.message.includes('work_station_checklist')?'Falta activar los pasos en Supabase.':e.message)}finally{setBusy(false)}}
 useEffect(()=>{setOpen(false);setSteps([]);setError('')},[station,ticket])
 return <section className="space-y-3"><Button variant="outline" className="w-full" disabled={busy} onClick={()=>load()}>Ver y completar pasos de la tarea</Button>{open&&<><p className="text-sm text-gray-500">Completa los obligatorios antes de finalizar.</p>{steps.length===0&&<p>No hay pasos configurados para este fichaje.</p>}{steps.map(step=><label key={step.id} className="flex gap-3 border rounded-lg p-3 min-h-12"><input className="h-6 w-6 shrink-0" type="checkbox" checked={!!step.done} disabled={busy} onChange={e=>load(step.id,e.target.checked)}/><span className="min-w-0 break-words">{step.title}<small className="block text-gray-500">{step.required?'Obligatorio':'Opcional'}</small></span></label>)}</>}{busy&&<p role="status">Guardando pasos…</p>}{error&&<p role="alert" className="text-red-700">{error}</p>}</section>
}
