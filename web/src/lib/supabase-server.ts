import { cookies } from 'next/headers'
import { createServerSupabaseClient } from '@supabase/ssr'

export function createServerClient() {
  return createServerSupabaseClient({
    cookies,
    supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL!,
    supabaseKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  })
}
