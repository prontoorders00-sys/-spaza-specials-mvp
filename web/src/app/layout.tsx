import "./globals.css";

export const metadata = {
  title: "SpazaSpecials",
  description: "Wholesale deals for informal retail"
};

export default function RootLayout({
  children
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-ink text-cream font-body min-h-screen">
        <main className="max-w-3xl mx-auto p-4">{children}</main>
      </body>
    </html>
  );
}
