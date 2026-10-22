import { createClient } from '@supabase/supabase-js'
import {organizationFetch} from './organizationScope'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  global:{fetch:organizationFetch},
  auth: {
    // Recovery links are consumed by an isolated client on that page.
    detectSessionInUrl: typeof window === 'undefined' || window.location.pathname !== '/reset-password'
  }
})