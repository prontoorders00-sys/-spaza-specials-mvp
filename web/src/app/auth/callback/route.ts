import { NextResponse } from "next/server";

/**
 * Minimal callback route for magic-link redirects.
 *
 * Supabase magic links often deliver tokens in the URL fragment (hash),
 * which browsers do not send to the server. If your magic-link flow
 * uses a redirect with query params, handle them here and set cookies.
 *
 * This file is a scaffold — adapt it to your auth/session strategy.
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  // If your magic-link provider returns a session in query, exchange it here.
  // For now redirect to the wholesaler home.
  return NextResponse.redirect(new URL("/wh", url));
}
