import { createClient } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'
export async function workRpc(name, args, options = {}) {
  let request = supabase.rpc(name, args)
  if (options.signal) request = request.abortSignal(options.signal)
  const { data, error } = await request
  if (error) throw new Error(error.message || 'No se pudo confirmar la operación')
  return data
}
export async function getWorkMode() {
  const { data, error } = await supabase.rpc('work_mode')
  if (error?.code === 'PGRST202' || error?.code === '42883') return false
  if (error) throw new Error('No se pudo comprobar el modo de fichaje. Vuelve a intentarlo.')
  return data === true
}
export function workDate() {
  return new Intl.DateTimeFormat('sv-SE', { timeZone: 'Europe/Madrid', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date())
}
export function elapsedSince(value) {
  if (!value) return '00:00:00'
  const seconds = Math.max(0, Math.floor((Date.now() - new Date(value).getTime()) / 1000))
  return [Math.floor(seconds / 3600), Math.floor(seconds / 60) % 60, seconds % 60].map(n => String(n).padStart(2, '0')).join(':')
}

// The station never borrows an employee/admin session to perform a check-in.
const stationClient = createClient(import.meta.env.VITE_SUPABASE_URL, import.meta.env.VITE_SUPABASE_ANON_KEY, {
  auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false, storageKey: 'ase-anonymous-station' }
})
export async function stationRpc(name, args) {
  const {data, error} = await stationClient.rpc(name, args)
  if (error) throw new Error(error.message || 'No se pudo confirmar la operación')
  return data
}
