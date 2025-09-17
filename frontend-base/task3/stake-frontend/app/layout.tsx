import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
// 导入 Providers 组件，需要确保 providers.tsx 文件存在于同级目录
import { Providers } from '@/app/providers';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Stake Frontend - 去中心化质押应用',
  description: '基于Web3的去中心化质押应用，支持代币质押、解除质押和奖励领取',
  keywords: ['Web3', 'DeFi', '质押', 'Staking', '区块链'],
  authors: [{ name: 'Stake Team' }],
};

export const viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#3b82f6',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="zh-CN">
      <body className={inter.className}>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}