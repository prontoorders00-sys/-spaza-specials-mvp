"use client";

/**
 * Browser Supabase client.
 * Only public anon key should be exposed to client-side code.
 * Place public keys in NEXT_PUBLIC_ environment variables.
 */

import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(url, anon);
