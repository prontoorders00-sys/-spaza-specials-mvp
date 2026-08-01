import Link from "next/link";

export default function WhHome() {
  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-3xl font-display">Wholesaler</h1>
        <Link href="/wh/login" className="text-dim underline">
          Sign in
        </Link>
      </div>

      <section className="bg-panel p-4 rounded border border-line">
        <h2 className="text-xl font-display mb-2">Dashboard (scaffold)</h2>
        <p className="text-dim">
          This is a placeholder page. Replace with authenticated UIs that respect
          RLS and confirmed_at rules.
        </p>
      </section>
    </div>
  );
}
