import { NextResponse } from 'next/server'
import { createServerSupabaseClient } from '@supabase/ssr'
import type { NextRequest } from 'next/server'

export async function POST(req: NextRequest) {
  const res = NextResponse.next()
  const supabase = createServerSupabaseClient({ req, res })
  const url = new URL(req.url)
  const code = url.searchParams.get('code')

  if (!code) return NextResponse.redirect(new URL('/', req.url))

  // exchangeCodeForSession is handled by Supabase SDK helper for OAuth flows
  // This illustrates calling the SDK to exchange the code
  const { data, error } = await supabase.auth.exchangeCodeForSession({ code })
  if (error) {
    return NextResponse.redirect(new URL('/login?error=auth', req.url))
  }

  // Session persisted by @supabase/ssr helpers via cookies
  return NextResponse.redirect(new URL(process.env.NEXT_PUBLIC_SITE_URL || '/', req.url))
}
