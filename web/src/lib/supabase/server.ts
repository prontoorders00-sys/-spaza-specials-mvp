/**
 * Server-side Supabase helpers (using @supabase/ssr).
 * - Do NOT put service role keys into committed client code.
 * - Use process.env.SUPABASE_SERVICE_ROLE_KEY only on server.
 *
 * This file is a scaffold: adjust cookie/session handling to match your RLS setup.
 */

import type { Request } from "next/server";
import { createServerSupabaseClient } from "@supabase/ssr"; // placeholder import

export function createSupabaseServer(request: Request) {
  // createServerSupabaseClient will typically read cookies from the request
  // and return an authenticated server client. Adjust to exact API in the repo.
  return createServerSupabaseClient({
    supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL!,
    supabaseKey: process.env.SUPABASE_SERVICE_ROLE_KEY!
  }, { request });
}
