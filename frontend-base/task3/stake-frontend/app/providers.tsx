'use client';

import { ReactNode } from 'react';
import { WagmiConfig, createConfig, configureChains } from 'wagmi';
import { sepolia, hardhat } from 'wagmi/chains';
import { publicProvider } from 'wagmi/providers/public';
import { jsonRpcProvider } from 'wagmi/providers/jsonRpc';
import { RainbowKitProvider, getDefaultWallets } from '@rainbow-me/rainbowkit';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'react-hot-toast';

import '@rainbow-me/rainbowkit/styles.css';

// 配置链
const { chains, publicClient } = configureChains(
  [
    ...(process.env.NODE_ENV === 'development' ? [hardhat] : []),
    sepolia,
  ],
  [
    jsonRpcProvider({
      rpc: (chain) => ({
        http: process.env.NEXT_PUBLIC_RPC_URL || 'http://localhost:8545',
      }),
    }),
    publicProvider(),
  ]
);

// 配置钱包
const { connectors } = getDefaultWallets({
  appName: process.env.NEXT_PUBLIC_APP_NAME || 'Stake Frontend',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || 'demo',
  chains,
});

// 创建 Wagmi 配置
const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
});

// 创建 React Query 客户端
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 3,
      staleTime: 30000, // 30 seconds
    },
  },
});

interface ProvidersProps {
  children: ReactNode;
}

export function Providers({ children }: ProvidersProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <WagmiConfig config={wagmiConfig}>
        <RainbowKitProvider
          chains={chains}
          theme={{
            blurs: {
              modalOverlay: 'small',
            },
            colors: {
              accentColor: '#3b82f6',
              accentColorForeground: 'white',
              actionButtonBorder: 'rgba(255, 255, 255, 0.04)',
              actionButtonBorderMobile: 'rgba(255, 255, 255, 0.08)',
              actionButtonSecondaryBackground: 'rgba(255, 255, 255, 0.08)',
              closeButton: 'rgba(224, 232, 255, 0.6)',
              closeButtonBackground: 'rgba(255, 255, 255, 0.08)',
              connectButtonBackground: '#3b82f6',
              connectButtonBackgroundError: '#ef4444',
              connectButtonInnerBackground: 'linear-gradient(0deg, rgba(255, 255, 255, 0.075), rgba(255, 255, 255, 0.15))',
              connectButtonText: 'white',
              connectButtonTextError: 'white',
              connectionIndicator: '#22c55e',
              downloadBottomCardBackground: 'linear-gradient(126deg, rgba(255, 255, 255, 0) 9.49%, rgba(171, 171, 171, 0.04) 71.04%), #1e293b',
              downloadTopCardBackground: 'linear-gradient(126deg, rgba(171, 171, 171, 0.2) 9.49%, rgba(255, 255, 255, 0) 71.04%), #1e293b',
              error: '#ef4444',
              generalBorder: 'rgba(255, 255, 255, 0.08)',
              generalBorderDim: 'rgba(255, 255, 255, 0.04)',
              menuItemBackground: 'rgba(224, 232, 255, 0.1)',
              modalBackdrop: 'rgba(0, 0, 0, 0.5)',
              modalBackground: '#1e293b',
              modalBorder: 'rgba(255, 255, 255, 0.08)',
              modalText: '#f8fafc',
              modalTextDim: 'rgba(224, 232, 255, 0.3)',
              modalTextSecondary: 'rgba(255, 255, 255, 0.6)',
              profileAction: 'rgba(224, 232, 255, 0.1)',
              profileActionHover: 'rgba(224, 232, 255, 0.2)',
              profileForeground: '#1e293b',
              selectedOptionBorder: 'rgba(224, 232, 255, 0.1)',
              standby: '#fbbf24',
            },
            fonts: {
              body: 'Inter, system-ui, sans-serif',
            },
            radii: {
              actionButton: '12px',
              connectButton: '12px',
              menuButton: '12px',
              modal: '24px',
              modalMobile: '28px',
            },
            shadows: {
              connectButton: '0px 8px 32px rgba(0, 0, 0, 0.32)',
              dialog: '0px 8px 32px rgba(0, 0, 0, 0.32)',
              profileDetailsAction: '0px 2px 6px rgba(37, 41, 46, 0.04)',
              selectedOption: '0px 2px 6px rgba(0, 0, 0, 0.24)',
              selectedWallet: '0px 2px 6px rgba(0, 0, 0, 0.12)',
              walletLogo: '0px 2px 16px rgba(0, 0, 0, 0.16)',
            },
          }}
          modalSize="compact"
          initialChain={process.env.NODE_ENV === 'development' ? hardhat : sepolia}
        >
          {children}
          <Toaster
            position="top-right"
            toastOptions={{
              duration: 4000,
              style: {
                background: '#1e293b',
                color: '#f8fafc',
                border: '1px solid rgba(255, 255, 255, 0.1)',
                borderRadius: '12px',
                fontSize: '14px',
              },
              success: {
                iconTheme: {
                  primary: '#22c55e',
                  secondary: '#f8fafc',
                },
              },
              error: {
                iconTheme: {
                  primary: '#ef4444',
                  secondary: '#f8fafc',
                },
              },
            }}
          />
        </RainbowKitProvider>
      </WagmiConfig>
    </QueryClientProvider>
  );
}