import {useOrganization} from '@/components/auth/OrganizationProvider'
import {supabase} from '@/lib/supabase'
export function useAuth(){
 const context=useOrganization()
 return {user:context?.user || null,userData:context?.userData || null,loading:context?.loading ?? true,
 permissionsLoading:context?.loading ?? true,permissions:context?.permissions || [],roleName:context?.roleName || null,
 isAdmin:context?.userData?.is_admin===true,
 can:key=>context?.userData?.is_admin===true || context?.permissions?.includes(key)===true,
 signIn:(email,password)=>supabase.auth.signInWithPassword({email,password}),signOut:()=>supabase.auth.signOut()}
}
