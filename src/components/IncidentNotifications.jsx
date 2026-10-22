import {useEffect,useState} from 'react'
import {useNavigate} from 'react-router-dom'
import {Bell} from 'lucide-react'
import {Button} from '@/components/ui/button'
import {workRpc} from '@/lib/workflow'
import {usabilityReady} from '@/lib/workFeatures'
export default function IncidentNotifications(){
 const navigate=useNavigate(),[count,setCount]=useState(0),[enabled,setEnabled]=useState(false)
 useEffect(()=>{let live=true;usabilityReady().then(v=>{if(live)setEnabled(v)}).catch(()=>{});return()=>{live=false}},[])
 useEffect(()=>{if(!enabled)return;let live=true;const load=()=>workRpc('work_incident_inbox').then(d=>{if(live)setCount(d.notifications.filter(n=>!n.seen).length)}).catch(()=>{if(live)setCount(0)});load();const timer=setInterval(load,30000);window.addEventListener('focus',load);return()=>{live=false;clearInterval(timer);window.removeEventListener('focus',load)}},[enabled])
 if(!enabled)return null
 return <Button variant="outline" size="sm" aria-label={`Notificaciones de incidencias: ${count} sin leer`} title="Incidencias y notificaciones" onClick={()=>navigate('/incidents')}><Bell className="h-4 w-4"/>{count>0&&<span className="text-xs">{count>99?'99+':count}</span>}</Button>
}
