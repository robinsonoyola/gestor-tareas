import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'

export function useLegacyAuth(enabled=true) {
  const [user, setUser] = useState(null)
  const [userData, setUserData] = useState(null)
  const [permissions, setPermissions] = useState([])
  const [roleName, setRoleName] = useState(null)
  const [permissionsLoading, setPermissionsLoading] = useState(true)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if(!enabled)return
    // Obtener sesión actual
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null)
      if (session?.user) {
        fetchUserData(session.user.id)
      } else {
        setLoading(false)
      }
    })

    // Escuchar cambios en la autenticación
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null)
      if (session?.user) {
        fetchUserData(session.user.id)
      } else {
        setUserData(null)
        setLoading(false)
      }
    })

    return () => subscription.unsubscribe()
  }, [enabled])

  useEffect(() => {
    if(!enabled)return
    let live = true
    if (!user?.id) { setPermissions([]); setRoleName(null); setPermissionsLoading(false); return }
    setPermissionsLoading(true)
    const refresh = async () => {
      try {
        const {data,error} = await supabase.rpc('work_my_permissions')
        if (!live) return
        setPermissions(error ? [] : data?.permissions || []); setRoleName(error ? null : data?.role || null)
      } catch { if (live) {setPermissions([]);setRoleName(null)} }
      finally {if(live)setPermissionsLoading(false)}
    }
    refresh()
    const timer=setInterval(refresh,30000)
    window.addEventListener('focus',refresh)
    return()=>{live=false;clearInterval(timer);window.removeEventListener('focus',refresh)}
  },[user?.id,enabled])

  const fetchUserData = async (userId) => {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .single()

      if (error) throw error
      setUserData(data)
    } catch (error) {
      console.error('Error fetching user data:', error)
    } finally {
      setLoading(false)
    }
  }

  const signIn = async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    return { data, error }
  }

  const signOut = async () => {
    const { error } = await supabase.auth.signOut()
    return { error }
  }

  return {
    user,
    userData,
    loading,
    isAdmin: userData?.is_admin || false,
    permissions, roleName, permissionsLoading,
    can: key => userData?.is_admin === true || permissions.includes(key),
    signIn,
    signOut
  }
}