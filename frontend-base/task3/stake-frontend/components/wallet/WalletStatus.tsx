'use client';

import { useAccount, useBalance, useNetwork } from 'wagmi';
import { AlertCircle, CheckCircle, Wifi, WifiOff } from 'lucide-react';
import { formatEtherValue } from '@/utils/format';

interface WalletStatusProps {
  className?: string;
  showBalance?: boolean;
  showNetwork?: boolean;
  compact?: boolean;
}

export default function WalletStatus({
  className = '',
  showBalance = true,
  showNetwork = true,
  compact = false
}: WalletStatusProps) {
  const { address, isConnected, isConnecting, isDisconnected } = useAccount();
  const { data: balance, isLoading: balanceLoading } = useBalance({ address });
  const { chain } = useNetwork();

  if (isDisconnected) {
    return (
      <div className={`flex items-center gap-2 text-gray-500 ${className}`}>
        <WifiOff className="w-4 h-4" />
        {!compact && <span className="text-sm">未连接钱包</span>}
      </div>
    );
  }

  if (isConnecting) {
    return (
      <div className={`flex items-center gap-2 text-yellow-500 ${className}`}>
        <div className="w-4 h-4 border-2 border-yellow-500 border-t-transparent rounded-full animate-spin" />
        {!compact && <span className="text-sm">连接中...</span>}
      </div>
    );
  }

  if (!isConnected) {
    return (
      <div className={`flex items-center gap-2 text-red-500 ${className}`}>
        <AlertCircle className="w-4 h-4" />
        {!compact && <span className="text-sm">连接失败</span>}
      </div>
    );
  }

  return (
    <div className={`space-y-2 ${className}`}>
      {/* 连接状态 */}
      <div className="flex items-center gap-2 text-green-500">
        <CheckCircle className="w-4 h-4" />
        {!compact && <span className="text-sm font-medium">钱包已连接</span>}
      </div>

      {/* 网络状态 */}
      {showNetwork && chain && (
        <div className="flex items-center gap-2">
          <Wifi className="w-4 h-4 text-blue-500" />
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full" />
            <span className="text-sm text-gray-700 dark:text-gray-300">
              {chain.name}
            </span>
            {chain.unsupported && (
              <span className="text-xs bg-red-100 text-red-600 px-2 py-1 rounded">
                不支持
              </span>
            )}
          </div>
        </div>
      )}

      {/* 余额显示 */}
      {showBalance && balance && (
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full" />
          <div className="text-sm">
            {balanceLoading ? (
              <span className="text-gray-500">加载中...</span>
            ) : (
              <span className="text-gray-700 dark:text-gray-300">
                {formatEtherValue(balance.value)} {balance.symbol}
              </span>
            )}
          </div>
        </div>
      )}

      {/* 网络不支持警告 */}
      {chain?.unsupported && (
        <div className="flex items-center gap-2 p-2 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
          <AlertCircle className="w-4 h-4 text-red-500" />
          <span className="text-sm text-red-600 dark:text-red-400">
            当前网络不受支持，请切换到支持的网络
          </span>
        </div>
      )}
    </div>
  );
}