import {useEffect,useState} from 'react'
import Layout from '@/components/layout/Layout'
import {Card,CardHeader,CardTitle,CardContent} from '@/components/ui/card'
import {Button} from '@/components/ui/button'
import {Input} from '@/components/ui/input'
import {Label} from '@/components/ui/label'
import {workRpc} from '@/lib/workflow'
export default function WorkAreas(){
 const [data,setData]=useState(null),[name,setName]=useState(''),[members,setMembers]=useState([]),[error,setError]=useState(''),[busy,setBusy]=useState(false)
 const load=()=>workRpc('work_area_directory').then(setData).catch(e=>setError(e.message.includes('work_area_directory')?'Instala la actualización de áreas e incidencias en la base de pruebas.':e.message))
 useEffect(()=>{load()},[])
 const save=async e=>{e.preventDefault();setBusy(true);setError('');try{await workRpc('work_save_area',{p_name:name,p_members:members});setName('');setMembers([]);await load()}catch(e){setError(e.message)}finally{setBusy(false)}}
 return <Layout><div className="max-w-5xl mx-auto space-y-5"><h1 className="text-3xl font-bold">Áreas y responsables</h1><p className="text-gray-500">Las áreas reciben incidencias. Los roles siguen definiendo los permisos.</p>{error&&<p role="alert" className="text-red-700">{error}</p>}<Card><CardHeader><CardTitle>Crear o actualizar un área</CardTitle></CardHeader><CardContent><form className="space-y-4" onSubmit={save}><Label htmlFor="area-name">Nombre del área</Label><Input id="area-name" value={name} onChange={e=>setName(e.target.value)} minLength={2} maxLength={100} required/><fieldset className="space-y-2"><legend className="font-medium mb-2">Personas que recibirán las incidencias</legend>{data?.people.map(p=><label className="flex items-center gap-3" key={p.id}><input type="checkbox" checked={members.includes(p.id)} onChange={e=>setMembers(current=>e.target.checked?[...current,p.id]:current.filter(id=>id!==p.id))}/>{p.full_name}</label>)}</fieldset><Button disabled={busy||!data||!members.length}>{busy?'Guardando…':'Guardar área y responsables'}</Button></form></CardContent></Card>{data?.areas.map(a=><Card key={a.id}><CardContent className="pt-6 flex flex-wrap justify-between gap-3"><div><p className="font-semibold">{a.name}</p><p className="text-sm text-gray-500">{data.people.filter(p=>a.members.includes(p.id)).map(p=>p.full_name).join(', ')}</p></div><Button variant="outline" onClick={()=>{setName(a.name);setMembers(a.members);window.setTimeout(()=>document.getElementById('area-name')?.focus(),0)}}>Editar responsables</Button></CardContent></Card>)}</div></Layout>
}
