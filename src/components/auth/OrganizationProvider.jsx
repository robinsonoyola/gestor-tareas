import {createContext,useCallback,useContext,useEffect,useRef,useState} from 'react'
import {supabase} from '@/lib/supabase'
import {savedOrganization,setOrganizationScope,setTenantMode} from '@/lib/organizationScope'

const Context=createContext(null)
export const useOrganization=()=>useContext(Context)
export default function OrganizationProvider({children}) {
  const [state,setState]=useState({mode:'checking',user:null,userData:null,organizations:[],activeOrganizationId:null,permissions:[],roleName:null,loading:true,error:''})
  const generation=useRef(0)
  const alive=useRef(true)
  const identity=useRef(null)
  const refresh=useCallback(async (identityOverride=undefined) => {
    const request=++generation.current
    let step='la sesión'
    // A stalled browser token refresh or network call must not leave the route loading forever.
    const deadline=setTimeout(()=>{
      if(!alive.current || request!==generation.current)return
      generation.current++
      setState(previous=>({...previous,mode:'tenant',loading:false,userData:null,permissions:[],activeOrganizationId:null,
        error:`No se pudo comprobar ${step} a tiempo. Comprueba la conexión y pulsa Volver a intentar.`}))
    },15000)
    try {
      const {data,error}=identityOverride!==undefined ? {data:{session:{user:identityOverride}}} : await supabase.auth.getSession()
      if(error)throw error
      const user=data.session?.user || null
      if(!alive.current||request!==generation.current)return null
      identity.current=user?.id || null
      setState(previous=>previous.user?.id===user?.id && previous.mode!=='checking' ? previous : {...previous,user,loading:true,error:'',permissions:[],userData:null})
      if(!user) {
        setOrganizationScope(null,null)
        setState({mode:'checking',user:null,userData:null,organizations:[],activeOrganizationId:null,permissions:[],roleName:null,loading:false,error:''})
        return null
      }
      setOrganizationScope(user.id,savedOrganization(user.id))
      step='la empresa'
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
        step='los permisos'
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
    } finally {clearTimeout(deadline)}
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
      const nextUser=session?.user || null
      // SIGNED_IN also occurs when returning to a tab with an existing session.
      // Recheck permissions in the background without unmounting unsaved forms.
      if(event!=='SIGNED_OUT' && nextUser?.id && nextUser.id===identity.current){
        setTimeout(()=>refresh(nextUser).catch(()=>{}),0)
        return
      }
      generation.current++
      identity.current=nextUser?.id || null
      // A real account change/sign-out still clears all user and tenant context.
      setOrganizationScope(nextUser?.id || null,nextUser ? savedOrganization(nextUser.id) : null)
      setState({mode:'checking',user:nextUser,userData:null,organizations:[],activeOrganizationId:null,permissions:[],roleName:null,loading:true,error:''})
      setTimeout(()=>refresh(nextUser).catch(()=>{}),0)
    })
    const timer=setInterval(run,30000)
    window.addEventListener('focus',run)
    return()=>{alive.current=false;generation.current++;subscription.unsubscribe();clearInterval(timer);window.removeEventListener('focus',run)}
  },[refresh])
  return <Context.Provider value={{...state,refresh,selectOrganization}}>
    {children}
  </Context.Provider>
}
