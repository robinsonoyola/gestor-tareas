import {supabase} from './supabase'
export async function usabilityReady() {
  const {data,error}=await supabase.rpc('work_usability_ready')
  if(error && ['PGRST202','42883'].includes(error.code)) return false
  if(error) throw new Error('No se pudieron comprobar las nuevas funciones. Actualiza la página.')
  return data===true
}
