import {useOrganization} from './OrganizationProvider'
import {useAuth} from '@/hooks/useAuth'
import {Button} from '@/components/ui/button'
import {toast} from 'sonner'
export default function OrganizationChoice() {
 const context=useOrganization()
 const {signOut}=useAuth()
 const closeSession=async()=>{try{await signOut();window.location.replace('/login')}catch(error){toast.error(error?.message||'No se pudo cerrar la sesión.')}}
 return <main className="min-h-dvh flex items-center justify-center bg-gray-50 p-4">
  <section className="w-full max-w-md rounded-xl border bg-white p-6 space-y-4">
   <h1 className="text-xl font-semibold">Selecciona tu empresa</h1>
   {context.error && <p role="alert">{context.error}</p>}
   {!context.error && !context.organizations.length && <p>No tienes ninguna empresa activa disponible. Consulta con tu administrador.</p>}
   {context.organizations.map(item=><Button key={item.id} className="w-full" variant="outline" disabled={context.loading} onClick={()=>context.selectOrganization(item.id).catch(()=>{})}>{item.name}</Button>)}
   {context.error?.includes('la sesión a tiempo') && <><p className="text-sm text-gray-600">Cierra las otras pestañas de ASE Work y recarga el acceso para recuperar la sesión.</p><Button className="w-full" onClick={()=>window.location.replace('/login')}>Recargar acceso</Button></>}
   {context.error && <Button onClick={()=>context.refresh().catch(()=>{})}>Volver a intentar</Button>}
   <Button variant="outline" className="w-full" onClick={closeSession}>Cerrar sesión</Button>
  </section>
 </main>
}
