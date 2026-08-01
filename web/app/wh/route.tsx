import { createServerClient } from '../../src/lib/supabase-server'
import { NextResponse } from 'next/server'

export async function GET() {
  // Protect /wh by checking session server-side
  const supabase = createServerClient()
  const { data } = await supabase.auth.getSession()
  if (!data?.session) {
    return NextResponse.redirect('/login')
  }
  return NextResponse.next()
}
