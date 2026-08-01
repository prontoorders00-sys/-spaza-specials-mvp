import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { createServerSupabaseClient } from '@supabase/ssr'

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()
  const supabase = createServerSupabaseClient({ req, res })

  // Refresh session if needed
  const { data } = await supabase.auth.getSession()
  if (!data?.session) {
    // nothing to do
    return res
  }

  // Optionally refresh; placeholder for session refresh logic
  return res
}

export const config = {
  matcher: ['/', '/wh', '/app/:path*']
}
