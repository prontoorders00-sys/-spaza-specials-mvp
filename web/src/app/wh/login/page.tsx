"use client";

import { useState } from "react";
import { supabase } from "@/lib/supabase/client";

export default function WhLogin() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function sendMagicLink(e?: React.FormEvent) {
    e?.preventDefault();
    setLoading(true);
    setStatus(null);
    try {
      const { error } = await supabase.auth.signInWithOtp({
        email
      });
      if (error) {
        setStatus(error.message);
      } else {
        setStatus("Check your email for a magic link.");
      }
    } catch (err: any) {
      setStatus(err?.message ?? "Failed to send link");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-2xl font-display mb-4">Wholesaler sign in</h2>
      <form onSubmit={sendMagicLink} className="space-y-3">
        <label className="block">
          <span className="text-dim">Email</span>
          <input
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            type="email"
            className="mt-1 block w-full bg-panel text-cream border border-line rounded px-3 py-2"
          />
        </label>
        <div>
          <button
            type="submit"
            className="bg-orange px-4 py-2 rounded text-cream"
            disabled={loading}
          >
            {loading ? "Sending…" : "Send magic link"}
          </button>
        </div>
        {status && <p className="text-dim mt-2">{status}</p>}
      </form>
    </div>
  );
}
