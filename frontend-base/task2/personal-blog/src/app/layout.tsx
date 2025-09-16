import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: {
    default: '个人博客',
    template: '%s | 个人博客',
  },
  description: '基于 Next.js 和 Supabase 的现代化个人博客',
  keywords: ['博客', 'Next.js', 'React', 'TypeScript', 'Supabase'],
  authors: [{ name: '张三', url: 'https://zhangsan.dev' }],
  creator: '张三',
  publisher: '个人博客',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'),
  openGraph: {
    type: 'website',
    locale: 'zh_CN',
    url: process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000',
    siteName: '个人博客',
    title: '个人博客',
    description: '基于 Next.js 和 Supabase 的现代化个人博客',
    images: [
      {
        url: '/og-image.jpg',
        width: 1200,
        height: 630,
        alt: '个人博客',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: '个人博客',
    description: '基于 Next.js 和 Supabase 的现代化个人博客',
    images: ['/og-image.jpg'],
    creator: '@zhangsan',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  verification: {
    google: 'your-google-verification-code',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh-CN" className="scroll-smooth">
      <body className={`${inter.className} antialiased`}>
        <div className="min-h-screen flex flex-col">
          <Header />
          <main className="flex-1">
            {children}
          </main>
          <Footer />
        </div>
      </body>
    </html>
  )
}