import {useEffect,useState} from 'react'
import {workRpc} from '@/lib/workflow'
import {Button} from '@/components/ui/button'
import {Dialog,DialogContent,DialogDescription,DialogHeader,DialogTitle} from '@/components/ui/dialog'
import {ImportanceBadge} from '@/components/TaskImportance'

const stateName={pending:'Pendiente',active:'En curso',paused:'Pausada',blocked:'Bloqueada',review:'En revisión',completed:'Completada',cancelled:'Cancelada'}

export default function TaskDependencies({task,tasks,onClose}){
 const [items,setItems]=useState([]),[selected,setSelected]=useState(''),[busy,setBusy]=useState(true),[error,setError]=useState('')
 const load=async()=>{setBusy(true);setError('');try{setItems(await workRpc('work_task_dependency_directory',{p_task:task.id}))}catch(e){setError(e.message?.includes('work_task_dependency_directory')?'Falta activar las dependencias en Supabase.':e.message)}finally{setBusy(false)}}
 useEffect(()=>{load()},[task.id])
 const change=async(action,prerequisite)=>{setBusy(true);setError('');try{await workRpc('work_manage_task_dependency',{p_action:action,p_task:task.id,p_prerequisite:prerequisite});setSelected('');await load()}catch(e){setError(e.message);setBusy(false)}}
 const linked=new Set(items.map(item=>item.id)),available=tasks.filter(item=>item.id!==task.id&&!linked.has(item.id))
 return <Dialog open onOpenChange={open=>!open&&onClose()}><DialogContent className="max-w-2xl"><DialogHeader><DialogTitle>Dependencias de {task.title}</DialogTitle><DialogDescription>Selecciona qué actividades deben completarse antes de permitir el inicio de esta tarea.</DialogDescription></DialogHeader><div className="space-y-4">
  <div className="rounded-lg border p-3 space-y-2"><label htmlFor="dependency-select" className="text-sm font-medium">Debe completarse primero</label><div className="flex flex-col gap-2 sm:flex-row"><select id="dependency-select" className="min-w-0 flex-1 rounded-md border bg-white p-2" value={selected} onChange={e=>setSelected(e.target.value)}><option value="">Selecciona una actividad requisito</option>{available.map(item=><option key={item.id} value={item.id}>{item.title}</option>)}</select><Button type="button" disabled={busy||!selected} onClick={()=>change('link',selected)}>Añadir dependencia</Button></div></div>
  {error&&<p role="alert" className="text-red-700">{error}</p>}{busy&&<p role="status">Actualizando dependencias…</p>}
  {!busy&&!error&&items.length===0&&<p className="rounded-lg border p-4 text-gray-600">Esta actividad puede comenzar sin depender de otra.</p>}
  <div className="space-y-3">{items.map(item=><article key={item.id} className="rounded-lg border bg-white p-4 space-y-2"><div className="flex flex-wrap items-start justify-between gap-2"><h3 className="font-semibold break-words">{item.title}</h3><ImportanceBadge value={item.importance}/></div><p className="text-sm">Última ejecución: {item.latest_date?`${stateName[item.latest_state]||item.latest_state} · ${item.latest_date}`:'Sin planificación'}</p><p className={item.latest_state==='completed'?'text-sm text-green-700':'text-sm text-amber-800'}>{item.latest_state==='completed'?'Requisito completado':'Impide comenzar hasta completarse'}</p><Button type="button" variant="outline" disabled={busy} onClick={()=>change('unlink',item.id)}>Quitar dependencia</Button></article>)}</div>
  <p className="text-xs text-gray-600">ASE Work valida esta regla también en móvil, NFC, tablet e inicio administrativo. Quitarla no elimina ninguna actividad.</p>
 </div></DialogContent></Dialog>
}
