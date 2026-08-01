import { NextRequest, NextResponse } from "next/server";

/**
 * Minimal middleware placeholder.
 * Add session checks, i18n, or edge logic here as needed.
 */
export function middleware(req: NextRequest) {
  // Example: allow all routes; future work: protect /wh routes, attach session info.
  return NextResponse.next();
}

export const config = {
  matcher: "/*"
};
