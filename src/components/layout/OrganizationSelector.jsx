import {useOrganization} from '@/components/auth/OrganizationProvider'
export default function OrganizationSelector(){
 const context=useOrganization()
 if(context?.mode!=='tenant'||context.organizations.length<2)return null
 return <label className="min-w-0 max-w-40 sm:max-w-56"><span className="sr-only">Empresa activa</span>
  <select aria-label="Empresa activa" className="w-full min-w-0 rounded-md border bg-white p-2 text-sm" value={context.activeOrganizationId||''} disabled={context.loading} onChange={e=>context.selectOrganization(e.target.value).catch(()=>{})}>
   {context.organizations.map(item=><option key={item.id} value={item.id}>{item.name}</option>)}
  </select>
 </label>
}
