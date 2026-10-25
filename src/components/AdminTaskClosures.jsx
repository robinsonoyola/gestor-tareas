import {useEffect,useState} from 'react'
import {useAuth} from '@/hooks/useAuth'
import {workRpc} from '@/lib/workflow'
import {usabilityReady} from '@/lib/workFeatures'
import {Card,CardHeader,CardTitle,CardContent} from '@/components/ui/card'
import {Button} from '@/components/ui/button'
import {Label} from '@/components/ui/label'
import {Input} from '@/components/ui/input'
export default function AdminTaskClosures({onChanged}){
 const {isAdmin}=useAuth(),[rows,setRows]=useState([]),[history,setHistory]=useState([]),[selected,setSelected]=useState(null),[reason,setReason]=useState(''),[error,setError]=useState(''),[busy,setBusy]=useState(false)
 const load=()=>Promise.all([workRpc('work_open_tasks'),workRpc('work_closure_history')]).then(([open,closed])=>{setRows(open);setHistory(Array.isArray(closed)?closed:[])}).catch(e=>setError(e.message))
 useEffect(()=>{if(isAdmin)usabilityReady().then(v=>{if(v)load()}).catch(e=>setError(e.message))},[isAdmin])
 if(!isAdmin)return null
 const finish=async()=>{setBusy(true);setError('');try{await workRpc('work_save_execution_result',{p_plan:selected.id,p_result:reason});await workRpc('work_admin_finish',{p_plan:selected.id,p_reason:reason});setSelected(null);setReason('');await load();onChanged?.()}catch(e){setError(e.message)}finally{setBusy(false)}}
 return <Card><CardHeader><CardTitle>Finalización por administrador</CardTitle></CardHeader><CardContent className="space-y-3"><p className="text-sm text-gray-500">Utiliza esta opción si el empleado no puede finalizar en la tablet. El motivo y tu identidad quedan registrados.</p>{error&&<p role="alert" className="text-red-700">{error}</p>}{!rows.length&&<p className="text-sm text-gray-500">No hay tareas en curso disponibles para cierre administrativo.</p>}{rows.map(row=><div key={row.id} className="border rounded-lg p-3 flex flex-wrap gap-3 justify-between"><div>{row.title}<p className="text-sm text-gray-500">{row.employee}</p></div><Button variant="outline" onClick={()=>{setSelected(row);setReason('')}}>Finalizar por el empleado</Button></div>)}{selected&&<section className="border rounded-lg p-4 space-y-3"><p className="font-medium">Finalizar: {selected.title} · {selected.employee}</p><Label htmlFor="admin-close-reason">Motivo obligatorio</Label><Input id="admin-close-reason" value={reason} onChange={e=>setReason(e.target.value)} maxLength={2000}/><div className="flex flex-wrap gap-3"><Button disabled={busy||reason.trim().length<5} onClick={finish}>Confirmar finalización</Button><Button variant="outline" disabled={busy} onClick={()=>setSelected(null)}>Cancelar</Button></div></section>}{history.length>0&&<section className="space-y-3 border-t pt-4"><h3 className="font-semibold">Últimos cierres registrados</h3>{history.map(item=><div key={item.id} className="border rounded-lg p-3"><p>{item.title} · {item.employee}</p><p className="text-sm text-gray-500">{item.kind==='admin_finish'?'Finalización administrativa':'Bloqueo por incidencia'} · {item.actor} · {new Date(item.created_at).toLocaleString('es-ES')}</p><p className="whitespace-pre-wrap">{item.reason}</p></div>)}</section>}</CardContent></Card>
}
