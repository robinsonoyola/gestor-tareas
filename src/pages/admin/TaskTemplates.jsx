import {useEffect,useState} from 'react'
import {workRpc} from '@/lib/workflow'
import {Button} from '@/components/ui/button'
import {Card,CardContent,CardHeader,CardTitle} from '@/components/ui/card'
import {Dialog,DialogContent,DialogDescription,DialogHeader,DialogTitle} from '@/components/ui/dialog'
import {Input} from '@/components/ui/input'
import {Label} from '@/components/ui/label'
import {Textarea} from '@/components/ui/textarea'
import {ImportanceBadge} from '@/components/TaskImportance'

export default function TaskTemplates({tasks,onCreated,canCreate,canEdit}){
 const [items,setItems]=useState([]),[busy,setBusy]=useState(true),[error,setError]=useState(''),[creating,setCreating]=useState(false),[editing,setEditing]=useState(null),[using,setUsing]=useState(null),[search,setSearch]=useState('')
 const [form,setForm]=useState({task:'',name:'',description:''}),[title,setTitle]=useState('')
 const load=async()=>{setBusy(true);setError('');try{setItems(await workRpc('work_task_template_directory'))}catch(e){setError(e.message?.includes('work_task_template_directory')?'Falta activar la biblioteca de plantillas en Supabase.':e.message)}finally{setBusy(false)}}
 useEffect(()=>{load()},[])
 const chooseTask=value=>{const task=tasks.find(item=>item.id===value);setForm(current=>({...current,task:value,name:current.name||task?.title||''}))}
 const openNew=()=>{setEditing(null);setForm({task:'',name:'',description:''});setCreating(true)}
 const openEdit=item=>{setEditing(item);setForm({task:item.source_task_id,name:item.name,description:item.description||''});setCreating(true)}
 const closeForm=()=>{setCreating(false);setEditing(null);setForm({task:'',name:'',description:''})}
 const save=async event=>{event.preventDefault();setBusy(true);setError('');try{await workRpc('work_save_task_template',{p_action:editing?'update':'create',p_id:editing?.id||null,p_task:form.task,p_name:form.name,p_description:form.description||null});closeForm();await load()}catch(e){setError(e.message);setBusy(false)}}
 const create=async event=>{event.preventDefault();setBusy(true);setError('');try{await workRpc('work_create_task_from_template',{p_template:using.id,p_title:title.trim()||using.name});setUsing(null);setTitle('');await onCreated?.();await load()}catch(e){setError(e.message);setBusy(false)}}
 const remove=async item=>{if(!window.confirm(`¿Eliminar la plantilla “${item.name}”? La actividad modelo no se eliminará.`))return;setBusy(true);setError('');try{await workRpc('work_save_task_template',{p_action:'delete',p_id:item.id});await load()}catch(e){setError(e.message);setBusy(false)}}
 const filtered=items.filter(item=>`${item.name} ${item.description||''} ${item.source_title}`.toLocaleLowerCase('es').includes(search.trim().toLocaleLowerCase('es')))
 return <div className="space-y-5">
  <div className="flex flex-wrap items-center justify-between gap-3"><div><h2 className="text-xl font-semibold">Biblioteca de plantillas</h2><p className="text-sm text-gray-600">Crea actividades limpias reutilizando configuración, responsables, checklist y evidencias.</p></div>{canCreate&&<Button type="button" onClick={openNew}>Nueva plantilla</Button>}</div>
  {items.length>0&&<Input aria-label="Buscar plantillas" value={search} onChange={e=>setSearch(e.target.value)} placeholder="Buscar por plantilla, descripción o actividad modelo"/>}
  {error&&<p role="alert" className="text-red-700">{error}</p>}{busy&&<p role="status">Actualizando plantillas…</p>}
  {!busy&&!error&&items.length===0&&<Card><CardContent className="py-10 text-center text-gray-600">Todavía no hay plantillas. Guarda una actividad existente como primer modelo.</CardContent></Card>}
  {!busy&&items.length>0&&filtered.length===0&&<p role="status" className="text-gray-600">No hay plantillas que coincidan con la búsqueda.</p>}
  <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">{filtered.map(item=><Card key={item.id}><CardHeader><CardTitle className="break-words">{item.name}</CardTitle></CardHeader><CardContent className="space-y-3"><ImportanceBadge value={item.importance}/><p className="text-sm text-gray-600 break-words">{item.description||'Sin descripción de plantilla.'}</p><p className="text-sm">Modelo vinculado: <strong>{item.source_title}</strong></p><div className="flex flex-wrap gap-2">{canCreate&&<Button type="button" disabled={busy} onClick={()=>{setUsing(item);setTitle(item.name)}}>Crear actividad</Button>}{canEdit&&<Button type="button" variant="outline" disabled={busy} onClick={()=>openEdit(item)}>Editar</Button>}{canEdit&&<Button type="button" variant="outline" disabled={busy} onClick={()=>remove(item)}>Eliminar plantilla</Button>}</div></CardContent></Card>)}</div>
  <Dialog open={creating} onOpenChange={open=>{if(!open)closeForm()}}><DialogContent><DialogHeader><DialogTitle>{editing?'Editar plantilla':'Guardar actividad como plantilla'}</DialogTitle><DialogDescription>La plantilla utilizará la configuración vigente de la actividad modelo.</DialogDescription></DialogHeader><form className="space-y-4" onSubmit={save}><div><Label htmlFor="template-task">Actividad modelo</Label><select id="template-task" required className="w-full rounded-md border bg-white p-2" value={form.task} onChange={e=>chooseTask(e.target.value)}><option value="">Selecciona una actividad</option>{tasks.map(task=><option key={task.id} value={task.id}>{task.title}</option>)}</select></div><div><Label htmlFor="template-name">Nombre de la plantilla</Label><Input id="template-name" required maxLength={120} value={form.name} onChange={e=>setForm(v=>({...v,name:e.target.value}))}/></div><div><Label htmlFor="template-description">Descripción de uso</Label><Textarea id="template-description" maxLength={500} value={form.description} onChange={e=>setForm(v=>({...v,description:e.target.value}))} placeholder="Cuándo conviene utilizar esta plantilla"/></div><Button className="w-full" disabled={busy||!form.task||!form.name.trim()}>{editing?'Guardar cambios':'Guardar plantilla'}</Button></form></DialogContent></Dialog>
  <Dialog open={!!using} onOpenChange={open=>!open&&setUsing(null)}><DialogContent><DialogHeader><DialogTitle>Crear desde plantilla</DialogTitle><DialogDescription>Se copiará la configuración de “{using?.source_title}”, nunca sus ejecuciones ni historial.</DialogDescription></DialogHeader><form className="space-y-4" onSubmit={create}><div><Label htmlFor="template-new-title">Título de la nueva actividad</Label><Input id="template-new-title" required maxLength={200} value={title} onChange={e=>setTitle(e.target.value)}/></div><Button className="w-full" disabled={busy||!title.trim()}>Crear actividad limpia</Button></form></DialogContent></Dialog>
 </div>
}
