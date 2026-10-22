import {createContext,useCallback,useContext,useEffect,useRef,useState,Fragment} from 'react'
import {supabase} from '@/lib/supabase'
import {savedOrganization,setOrganizationScope,setTenantMode} from '@/lib/organizationScope'

const Context=createContext(null)
export const useOrganization=()=>useContext(Context)
export default function OrganizationProvider({children}) {
  const [state,setState]=useState({mode:'checking',user:null,userData:null,organizations:[],activeOrganizationId:null,permissions:[],roleName:null,loading:true,error:''})
  const generation=useRef(0)
  const alive=useRef(true)
  const refresh=useCallback(async (identityOverride) => {
    const request=++generation.current
    try {
      const {data,error}=identityOverride ? {data:{session:{user:identityOverride}}} : await supabase.auth.getSession()
      if(error)throw error
      const user=data.session?.user || null
      if(!alive.current||request!==generation.current)return null
      setState(previous=>previous.user?.id===user?.id && previous.mode!=='checking' ? previous : {...previous,user,loading:true,error:'',permissions:[],userData:null})
      if(!user) {
        setOrganizationScope(null,null)
        setState({mode:'checking',user:null,userData:null,organizations:[],activeOrganizationId:null,permissions:[],roleName:null,loading:false,error:''})
        return null
      }
      setOrganizationScope(user.id,savedOrganization(user.id))
      let result=await supabase.rpc('mt_context')
      if(!alive.current||request!==generation.current)return null
      if(['PGRST202','42883'].includes(result.error?.code)) {
        setTenantMode('legacy')
        setState(previous=>({...previous,mode:'legacy',user,loading:false}))
        return {legacy:true}
      }
      if(result.error)throw result.error
      const list=result.data?.organizations || []
      let selected=result.data.active_organization_id
      if(!selected && list.length===1)selected=list[0].id
      if(!selected || selected!==result.data.active_organization_id) {
        setOrganizationScope(user.id,selected || null)
        result=await supabase.rpc('mt_context')
        if(result.error)throw result.error
      }
      if(!alive.current||request!==generation.current)return null
      selected=result.data.active_organization_id
      setOrganizationScope(user.id,selected)
      setTenantMode('tenant')
      let permissions={permissions:[],role:null}
      if(selected) {
        const response=await supabase.rpc('work_my_permissions')
        if(response.error)throw response.error
        permissions=response.data
      }
      if(!alive.current||request!==generation.current)return null
      const next={mode:'tenant',user,userData:result.data.profile,organizations:result.data.organizations,activeOrganizationId:selected,
        permissions:permissions.permissions || [],roleName:permissions.role || null,loading:false,error:''}
      setState(next)
      return next
    } catch(error) {
      if(alive.current && request===generation.current) {
        setState(previous=>({...previous,mode:'tenant',loading:false,error:'No se pudo verificar la empresa y sus permisos. Vuelve a intentarlo.',userData:null,permissions:[],activeOrganizationId:null}))
      }
      throw error
    }
  },[])
  const selectOrganization=async id=>{
    const {data,error}=await supabase.auth.getSession()
    const user=data?.session?.user
    if(error||!user||!id)throw new Error('Empresa no disponible')
    generation.current++
    setState(previous=>({...previous,loading:true,userData:null,permissions:[],activeOrganizationId:null}))
    setOrganizationScope(user.id,id)
    await supabase.removeAllChannels()
    const result=await refresh(user)
    if(result && result.activeOrganizationId!==id)throw new Error('Empresa no disponible')
    return result
  }
  useEffect(()=>{
    alive.current=true
    const run=()=>refresh().catch(()=>{})
    run()
    const {data:{subscription}}=supabase.auth.onAuthStateChange((event,session)=>{
      if(event==='TOKEN_REFRESHED' || event==='INITIAL_SESSION'){setTimeout(run,0);return}
      generation.current++
      // Establish the authenticated identity before signInWithPassword resolves.
      // A concurrent profile/context request must share this scope, not be aborted by its setup.
      const nextUser=session?.user
      setOrganizationScope(nextUser?.id || null,nextUser ? savedOrganization(nextUser.id) : null)
      setState(previous=>({...previous,loading:true,userData:null,permissions:[],activeOrganizationId:null}))
      setTimeout(run,0)
    })
    const timer=setInterval(run,30000)
    window.addEventListener('focus',run)
    return()=>{alive.current=false;generation.current++;subscription.unsubscribe();clearInterval(timer);window.removeEventListener('focus',run)}
  },[refresh])
  return <Context.Provider value={{...state,refresh,selectOrganization}}>
    {children}
  </Context.Provider>
}
