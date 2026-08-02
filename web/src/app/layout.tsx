import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Spaza Specials',
  description: 'Wholesale deals discovery for South Africa\'s informal retail',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-ink text-cream">
        {children}
      </body>
    </html>
  );
}
