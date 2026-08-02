'use client';

import { createClient } from '@/lib/supabase/client';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const router = useRouter();
  const supabase = createClient();

  const handleGoogleSignIn = async () => {
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback`,
      },
    });

    if (error) {
      console.error('Sign in error:', error);
    }
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-orange mb-2">Spaza Specials</h1>
          <p className="text-dim">Sign in to browse wholesale deals</p>
        </div>
        <button
          onClick={handleGoogleSignIn}
          className="w-full bg-orange text-ink font-semibold py-3 px-4 rounded hover:bg-orange-dark focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-orange transition-colors"
        >
          Sign in with Google
        </button>
      </div>
    </main>
  );
}
