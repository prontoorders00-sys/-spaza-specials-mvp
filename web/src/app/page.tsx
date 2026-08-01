export default function Home() {
  return (
    <div>
      <h1 className="text-4xl font-display mb-4">SpazaSpecials</h1>
      <p className="text-dim mb-6">
        Wholesale deals discovery for South Africa’s informal retail.
      </p>

      <div className="space-x-3">
        <a
          className="inline-block bg-orange px-4 py-2 rounded text-cream"
          href="/wh"
        >
          Wholesaler dashboard
        </a>
        <a className="inline-block border border-line px-4 py-2 rounded text-cream" href="/wh/login">
          Sign in (wholesaler)
        </a>
      </div>
    </div>
  );
}
