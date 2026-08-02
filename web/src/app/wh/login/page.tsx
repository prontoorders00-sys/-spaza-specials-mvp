'use client';

import { createClient } from '@/lib/supabase/client';
import { useState } from 'react';

export default function LoginPage() {
  const supabase = createClient();
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const { error } = await supabase.auth.signInWithOtp({
        email,
        options: {
          emailRedirectTo: `${window.location.origin}/auth/callback`,
        },
      });

      if (error) {
        setError(error.message);
      } else {
        setSubmitted(true);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  if (submitted) {
    return (
      <main className="flex min-h-screen flex-col items-center justify-center p-4">
        <div className="w-full max-w-md text-center space-y-4">
          <div className="text-4xl mb-4">📧</div>
          <h1 className="text-3xl font-bold text-orange mb-2">Check your email</h1>
          <p className="text-cream mb-2">We sent a magic link to:</p>
          <p className="text-dim font-mono">{email}</p>
          <p className="text-dim text-sm pt-4">Click the link in your email to sign in. The link expires in 24 hours.</p>
        </div>
      </main>
    );
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-orange mb-2">Spaza Specials</h1>
          <p className="text-dim">Sign in to browse wholesale deals</p>
        </div>

        <form onSubmit={handleSignIn} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm text-cream mb-2">
              Email
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              required
              className="w-full px-4 py-3 bg-panel text-cream border border-line rounded focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-orange"
              disabled={loading}
            />
          </div>

          {error && (
            <div className="p-3 bg-alert/10 border border-alert rounded text-alert text-sm">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading || !email}
            className="w-full bg-orange text-ink font-semibold py-3 px-4 rounded hover:bg-orange-dark focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-orange transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? 'Sending link...' : 'Send magic link'}
          </button>
        </form>
      </div>
    </main>
  );
}
