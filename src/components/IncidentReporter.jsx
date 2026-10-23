import {forwardRef,useEffect,useImperativeHandle,useState} from 'react'
import {useNavigate} from 'react-router-dom'
import {useAuth} from '@/hooks/useAuth'
import {supabase} from '@/lib/supabase'
import {workRpc} from '@/lib/workflow'
import {usabilityReady} from '@/lib/workFeatures'
import {taskAttachmentId,taskAttachmentExtension} from '@/lib/taskAttachments'
import {Card,CardHeader,CardTitle,CardContent} from '@/components/ui/card'
import {Button} from '@/components/ui/button'
import {Label} from '@/components/ui/label'
import {Input} from '@/components/ui/input'
import {Textarea} from '@/components/ui/textarea'
export default forwardRef(function IncidentReporter({taskId,hideTrigger=false,onReported},ref){
 const {user}=useAuth(),navigate=useNavigate(),[open,setOpen]=useState(false),[directory,setDirectory]=useState(null),[ready,setReady]=useState(null),[target,setTarget]=useState(''),[subject,setSubject]=useState(''),[description,setDescription]=useState(''),[block,setBlock]=useState(false),[files,setFiles]=useState([]),[busy,setBusy]=useState(false),[error,setError]=useState(''),[sent,setSent]=useState(false)
 useEffect(()=>{let live=true;usabilityReady().then(v=>{if(live)setReady(v)}).catch(e=>{if(live)setError(e.message)});return()=>{live=false}},[])
 const show=async()=>{setOpen(true);setError('');try{setDirectory(await workRpc('work_area_directory'))}catch(e){setError(e.message)}}
 useImperativeHandle(ref,()=>({open:show}))
 const send=async e=>{e.preventDefault();setBusy(true);setError('');try{
  if(!user?.id||!target)throw new Error('Selecciona un responsable o área.')
  if(files.length>3)throw new Error('Adjunta hasta tres imágenes.')
  const paths=[]
  for(const file of files){const ext=taskAttachmentExtension(file,'image');const path=`tasks/${taskId}/${user.id}/${taskAttachmentId()}.${ext}`;const {error}=await supabase.storage.from('task-files').upload(path,file,{upsert:false,contentType:file.type});if(error)throw error;paths.push(path)}
  const [kind,value]=target.split(':');const incidentId=await workRpc('work_report_incident',{p_task:taskId,p_subject:subject,p_description:description,p_user:kind==='user'?value:null,p_area:kind==='area'?value:null,p_block:block,p_files:paths})
  setSent(true);setFiles([])
  // The incident and optional closure have committed before updating the task screen.
  onReported?.({blocked:block,incidentId})
 }catch(e){setError(e.message)}finally{setBusy(false)}}
 if(hideTrigger&&!open&&!sent)return null
 return <Card><CardHeader><CardTitle>Incidencias</CardTitle></CardHeader><CardContent className="space-y-4">{!open&&!sent&&<><Button variant="outline" disabled={!ready} onClick={show}>Reportar incidencia</Button>{ready===false&&<p className="text-sm text-gray-500">Disponible al instalar la actualización de incidencias en la base de pruebas.</p>}</>}{error&&<p role="alert" className="text-red-700">{error}</p>}{sent?<div role="status" className="space-y-3"><p>Incidencia registrada. Los responsables recibieron una notificación en ASE Work.</p>{block&&<p>El contador se ha detenido. La tarea está bloqueada por incidencia y no cuenta como completada.</p>}<Button onClick={()=>navigate('/incidents')}>Consultar seguimiento</Button></div>:open&&<form className="space-y-4" onSubmit={send}><div><Label htmlFor="incident-target">Área o persona responsable</Label><select id="incident-target" className="w-full min-w-0 border rounded-md bg-white p-2" value={target} onChange={e=>setTarget(e.target.value)} required><option value="">Selecciona un destinatario</option><optgroup label="Áreas">{directory?.areas.map(a=><option key={a.id} value={`area:${a.id}`}>{a.name}</option>)}</optgroup><optgroup label="Personas">{directory?.people.map(p=><option key={p.id} value={`user:${p.id}`}>{p.full_name}</option>)}</optgroup></select></div><div><Label htmlFor="incident-subject">Título</Label><Input id="incident-subject" value={subject} onChange={e=>setSubject(e.target.value)} minLength={3} maxLength={160} required/></div><div><Label htmlFor="incident-description">Qué ha ocurrido</Label><Textarea id="incident-description" value={description} onChange={e=>setDescription(e.target.value)} minLength={3} maxLength={5000} required/></div><div><Label htmlFor="incident-images">Hasta 3 imágenes · máximo 5 MB cada una</Label><Input id="incident-images" type="file" multiple accept="image/png,image/jpeg,image/gif,image/webp" onChange={e=>setFiles([...e.target.files])}/></div><label className="flex gap-3 items-start w-full min-h-14 rounded-lg border p-4 cursor-pointer"><input type="checkbox" className="h-6 w-6 shrink-0 mt-0.5 accent-blue-600 cursor-pointer" checked={block} onChange={e=>setBlock(e.target.checked)}/><span className="text-sm leading-6">Este problema me impide continuar. Detener el contador y dejar la tarea bloqueada, sin completarla.</span></label>{block&&<p className="text-sm text-amber-800">Al enviar se cerrará tu fichaje en esta tarea. El administrador deberá revisar cómo retomarla.</p>}<div className="flex flex-wrap gap-3"><Button disabled={busy||!directory}>{busy?'Enviando…':block?'Enviar y detener tarea':'Enviar incidencia'}</Button><Button type="button" variant="outline" disabled={busy} onClick={()=>setOpen(false)}>Cancelar</Button></div></form>}</CardContent></Card>
})
