import {useEffect,useState} from 'react'
import {workRpc} from '@/lib/workflow'
import {Button} from '@/components/ui/button'
import {Dialog,DialogContent,DialogDescription,DialogHeader,DialogTitle} from '@/components/ui/dialog'
import {ImportanceBadge} from '@/components/TaskImportance'

const stateName={pending:'Pendiente',in_progress:'En progreso',completed:'Completada'}

export default function TaskSubtasks({task,tasks,onClose}){
 const [items,setItems]=useState([]),[selected,setSelected]=useState(''),[busy,setBusy]=useState(true),[error,setError]=useState('')
 const load=async()=>{setBusy(true);setError('');try{setItems(await workRpc('work_task_subtask_directory',{p_task:task.id}))}catch(e){setError(e.message?.includes('work_task_subtask_directory')?'Falta activar las subtareas en Supabase.':e.message)}finally{setBusy(false)}}
 useEffect(()=>{load()},[task.id])
 const change=async(action,child)=>{setBusy(true);setError('');try{await workRpc('work_manage_task_subtask',{p_action:action,p_parent:task.id,p_child:child});setSelected('');await load()}catch(e){setError(e.message);setBusy(false)}}
 const linked=new Set(items.map(item=>item.id)),available=tasks.filter(item=>item.id!==task.id&&!linked.has(item.id))
 return <Dialog open onOpenChange={open=>!open&&onClose()}><DialogContent className="max-w-2xl"><DialogHeader><DialogTitle>Subtareas de {task.title}</DialogTitle><DialogDescription>Son actividades independientes. Conservan responsables, planificación, estado y fichajes propios.</DialogDescription></DialogHeader><div className="space-y-4">
  <div className="rounded-lg border p-3 space-y-2"><label htmlFor="subtask-select" className="text-sm font-medium">Vincular una actividad existente</label><div className="flex flex-col gap-2 sm:flex-row"><select id="subtask-select" className="min-w-0 flex-1 rounded-md border bg-white p-2" value={selected} onChange={e=>setSelected(e.target.value)}><option value="">Selecciona una actividad</option>{available.map(item=><option key={item.id} value={item.id}>{item.title}</option>)}</select><Button type="button" disabled={busy||!selected} onClick={()=>change('link',selected)}>Añadir subtarea</Button></div><p className="text-xs text-gray-600">Vincular no duplica ni reordena la actividad seleccionada.</p></div>
  {error&&<p role="alert" className="text-red-700">{error}</p>}{busy&&<p role="status">Actualizando subtareas…</p>}
  {!busy&&!error&&items.length===0&&<p className="rounded-lg border p-4 text-gray-600">Esta actividad todavía no tiene subtareas.</p>}
  <div className="space-y-3">{items.map(item=><article key={item.id} className="rounded-lg border bg-white p-4 space-y-2"><div className="flex flex-wrap items-start justify-between gap-2"><div><h3 className="font-semibold break-words">{item.title}</h3><p className="text-sm text-gray-600">{item.assigned}</p></div><ImportanceBadge value={item.importance}/></div><p className="text-sm">{stateName[item.status]||item.status}{item.schedule_date?` · ${item.schedule_date}`:''}</p><Button type="button" variant="outline" disabled={busy} onClick={()=>change('unlink',item.id)}>Quitar relación</Button></article>)}</div>
  <p className="text-xs text-gray-600">Quitar la relación no elimina la actividad ni su historial. Las dependencias que impiden comenzar se configurarán por separado.</p>
 </div></DialogContent></Dialog>
}
