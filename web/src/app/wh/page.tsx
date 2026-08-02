import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export default async function WhPage() {
  const supabase = await createClient();
  const { data } = await supabase.auth.getUser();

  if (!data.user) {
    redirect('/wh/login');
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-4">
      <div className="text-center">
        <h1 className="text-3xl font-bold text-orange mb-2">Dashboard</h1>
        <p className="text-cream">Welcome, {data.user.email}</p>
      </div>
    </main>
  );
}
