import {useEffect,useState,useRef} from 'react'
import {useNavigate} from 'react-router-dom'
import {Input} from '@/components/ui/input'
import {Button} from '@/components/ui/button'
import {Card,CardHeader,CardTitle,CardContent} from '@/components/ui/card'
import {workRpc} from '@/lib/workflow'
import {parseWorkSearch} from '@/lib/workSearch'
import {usabilityReady} from '@/lib/workFeatures'
export default function WorkSearch(){
 const request=useRef(0),timer=useRef(null)
 const navigate=useNavigate(),[query,setQuery]=useState(''),[result,setResult]=useState(null),[error,setError]=useState(''),[busy,setBusy]=useState(false),[ready,setReady]=useState(null)
 useEffect(()=>{let live=true;usabilityReady().then(v=>{if(live)setReady(v)}).catch(e=>{if(live)setError(e.message)});return()=>{live=false}},[])
 const runSearch=async value=>{const generation=++request.current;setBusy(true);setError('');try{const data=await workRpc('work_search',parseWorkSearch(value));if(generation===request.current)setResult(data)}catch(e){if(generation===request.current){setResult(null);setError(e.message)}}finally{if(generation===request.current)setBusy(false)}}
 useEffect(()=>{request.current++;setResult(null);setBusy(false);if(ready&&query.trim().length>1)timer.current=setTimeout(()=>runSearch(query),450);return()=>{clearTimeout(timer.current);request.current++}},[query,ready])
 const search=e=>{e.preventDefault();clearTimeout(timer.current);if(ready&&query.trim())runSearch(query)}

 return <Card><CardHeader><CardTitle>Buscar en ASE Work</CardTitle></CardHeader><CardContent className="space-y-4"><form onSubmit={search} className="flex flex-col sm:flex-row gap-3"><Input aria-label="Buscar por palabras" placeholder="Ej.: tarea iniciada, incidencias pendientes, piscina Juan" value={query} onChange={e=>setQuery(e.target.value)} maxLength={160}/><Button disabled={!ready||busy||!query.trim()}>{busy?'Buscando…':'Buscar'}</Button></form>{ready===false&&<p className="text-sm text-gray-500">La búsqueda estará disponible al instalar la actualización de funciones en la base de pruebas.</p>}{error&&<p role="alert" className="text-red-700">{error}</p>}{result&&<><p className="text-sm text-gray-500">Hasta 100 resultados por grupo. Solo se muestran datos que puedes consultar.</p>{[['tasks','Tareas'],['people','Personas'],['incidents','Incidencias']].map(([key,title])=>result[key]?.length>0&&<section key={key} className="space-y-2"><h3 className="font-semibold">{title}</h3>{result[key].map(row=><div key={row.id} className="flex flex-wrap justify-between gap-3 border rounded-lg p-3"><div><p>{row.title||row.full_name||row.subject}</p><p className="text-sm text-gray-500">{row.employee} {row.work_date} {({active:'En curso',pending:'Pendiente',completed:'Completada',blocked:'Bloqueada',open:'Abierta',in_progress:'En atención',resolved:'Resuelta'})[row.state]}</p>{key==='incidents'&&<p>{row.subject}</p>}</div>{key==='tasks'&&row.can_open&&<Button variant="outline" onClick={()=>navigate(`/employee/task/${row.task_id}/work`)}>Abrir tarea</Button>}{key==='people'&&<Button variant="outline" onClick={()=>navigate('/admin/team')}>Ver equipo</Button>}{key==='incidents'&&<Button variant="outline" onClick={()=>navigate('/incidents')}>Ver incidencia</Button>}</div>)}</section>)}{['tasks','people','incidents'].every(key=>!result[key]?.length)&&<p role="status">No hay coincidencias con esas palabras.</p>}</>}</CardContent></Card>
}
