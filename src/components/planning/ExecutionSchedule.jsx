import {useEffect,useState} from 'react'
import {Button} from '@/components/ui/button'
import {Input} from '@/components/ui/input'
import {Label} from '@/components/ui/label'
import {workRpc} from '@/lib/workflow'

const labels={anytime:'En cualquier momento',deadline:'Antes de una fecha',window:'Entre dos fechas',scheduled:'En una fecha/hora concreta',period:'Durante un periodo'}
const local=value=>value?new Date(value).toLocaleString('es-ES',{timeZone:'Europe/Madrid',dateStyle:'medium',timeStyle:'short'}):''
export function ScheduleText({item,className='text-sm text-gray-500'}){
 if(!item)return null
 const kind=item.schedule_kind||item.kind
 let text=labels[kind]||'Planificada'
 if(kind==='deadline')text=`Disponible hasta ${local(item.due_at)}`
 if(kind==='window')text=`Disponible ${local(item.available_from)} – ${local(item.due_at)}`
 if(kind==='scheduled')text=`Programada · ${local(item.scheduled_for)}${item.strict_schedule||item.strict?' · estricta':' · flexible'}`
 if(kind==='period')text=`Periodo ${local(item.available_from)} – ${local(item.planned_end)}${item.due_at?` · límite ${local(item.due_at)}`:''}`
 if(item.overdue)text+=` · ${item.state==='active'?'En curso fuera de plazo':'Vencida'}`
 else if(item.starts_later)text+=' · Aún no disponible'
 const indicators=Number.isFinite(item.checklist_total)||Number.isFinite(item.comments_count)||Number.isFinite(item.attachments_count)||Number.isFinite(item.evidence_required)
 return <div className="space-y-2"><p className={className}>{text}</p>{indicators&&<div className="flex flex-wrap gap-1.5 text-xs" aria-label="Indicadores de la ejecución">{item.checklist_total>0&&<span className="rounded-full bg-slate-100 px-2 py-1 text-slate-800">✓ {item.checklist_done}/{item.checklist_total} pasos</span>}{item.comments_count>0&&<span className="rounded-full bg-slate-100 px-2 py-1 text-slate-800">💬 {item.comments_count}</span>}{item.attachments_count>0&&<span className="rounded-full bg-slate-100 px-2 py-1 text-slate-800">📎 {item.attachments_count}</span>}{item.evidence_required>0&&<span className={`rounded-full px-2 py-1 ${item.evidence_provided>=item.evidence_required?'bg-green-100 text-green-900':'bg-amber-100 text-amber-950'}`}>Evidencias {item.evidence_provided}/{item.evidence_required}</span>}</div>}</div>
}
const value=(iso)=>iso?new Date(iso).toLocaleString('sv-SE',{timeZone:'Europe/Madrid'}).replace(' ','T').slice(0,16):''
const initial=item=>({kind:item.schedule_kind||'scheduled',available:value(item.available_from),scheduled:value(item.scheduled_for),due:value(item.due_at),end:value(item.planned_end),strict:item.strict_schedule??true})
export function ScheduleEditor({item,onSaved,disabled=false}){
 const [open,setOpen]=useState(false),[form,setForm]=useState(()=>initial(item)),[busy,setBusy]=useState(false),[error,setError]=useState('')
 useEffect(()=>setForm(initial(item)),[item?.id,item?.version])
 const set=(key,v)=>setForm(x=>({...x,[key]:v}))
 const iso=v=>v?new Date(v).toISOString():null
 const validation=()=>{
  const missing=(field,label)=>!form[field]||!form[field].includes('T')?`Falta completar ${label}, incluida la hora.`:''
  let message=''
  if(['window','period'].includes(form.kind))message=missing('available','Disponible desde')
  if(!message&&form.kind==='scheduled')message=missing('scheduled','Fecha y hora programada')
  if(!message&&['deadline','window'].includes(form.kind))message=missing('due','Fecha límite')
  if(!message&&form.kind==='period')message=missing('end','Final previsto')
  if(message)return message
  if(form.kind==='window'&&new Date(form.available)>=new Date(form.due))return 'La fecha límite debe ser posterior a la disponibilidad.'
  if(form.kind==='scheduled'&&form.due&&new Date(form.scheduled)>=new Date(form.due))return 'La fecha límite debe ser posterior al momento programado.'
  if(form.kind==='period'&&new Date(form.available)>=new Date(form.end))return 'El final previsto debe ser posterior a la disponibilidad.'
  if(form.kind==='period'&&form.due&&new Date(form.available)>=new Date(form.due))return 'La fecha límite debe ser posterior a la disponibilidad.'
  return ''
 }
 const save=async()=>{const message=validation();if(message){setError(message);return}setBusy(true);setError('');try{await workRpc('work_set_execution_schedule',{p_plan:item.id,p_kind:form.kind,p_available_from:iso(form.available),p_scheduled_for:iso(form.scheduled),p_due_at:iso(form.due),p_planned_end:iso(form.end),p_strict:form.kind==='scheduled'&&form.strict,p_version:item.version,p_request:crypto.randomUUID()});setOpen(false);await onSaved?.()}catch(e){setError(e.message)}finally{setBusy(false)}}
 if(!open)return <Button type="button" variant="outline" size="sm" disabled={disabled} onClick={()=>setOpen(true)}>Editar fecha</Button>
 return <div className="basis-full border rounded-lg bg-gray-50 p-4 space-y-3"><h3 className="font-semibold">¿Cuándo debe hacerse?</h3><div><Label>Tipo</Label><select className="w-full border rounded-md bg-white p-2" value={form.kind} onChange={e=>set('kind',e.target.value)}>{Object.entries(labels).map(([k,v])=><option key={k} value={k}>{v}</option>)}</select></div>
 {['window','period'].includes(form.kind)&&<div><Label>Disponible desde · fecha y hora</Label><Input type="datetime-local" value={form.available} onChange={e=>set('available',e.target.value)}/></div>}
 {form.kind==='scheduled'&&<div><Label>Fecha y hora programada</Label><Input type="datetime-local" value={form.scheduled} onChange={e=>set('scheduled',e.target.value)}/></div>}
 {['deadline','window','scheduled','period'].includes(form.kind)&&<div><Label>Fecha límite · fecha y hora {['scheduled','period'].includes(form.kind)&&'(opcional)'}</Label><Input type="datetime-local" value={form.due} onChange={e=>set('due',e.target.value)}/></div>}
 {form.kind==='period'&&<div><Label>Final previsto · fecha y hora</Label><Input type="datetime-local" value={form.end} onChange={e=>set('end',e.target.value)}/></div>}
 {form.kind==='scheduled'&&<label className="flex gap-2 items-start"><input type="checkbox" className="mt-1" checked={form.strict} onChange={e=>set('strict',e.target.checked)}/><span><strong>Programación estricta</strong><small className="block text-gray-500">Impide empezar antes del momento programado. La flexible solo informa.</small></span></label>}
 {error&&<p role="alert" className="text-red-700">{error}</p>}<div className="flex gap-2 justify-end"><Button type="button" variant="outline" disabled={busy} onClick={()=>setOpen(false)}>Cancelar</Button><Button type="button" disabled={busy} onClick={save}>{busy?'Guardando…':'Guardar fechas'}</Button></div></div>
}
