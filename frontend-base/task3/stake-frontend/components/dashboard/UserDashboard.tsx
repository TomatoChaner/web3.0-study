'use client';

import { useState } from 'react';
import { 
  Wallet, 
  TrendingUp, 
  Clock, 
  Gift, 
  Eye, 
  EyeOff,
  RefreshCw,
  ExternalLink 
} from 'lucide-react';
import { formatTokenValue, formatPercentage, formatDuration } from '@/utils/format';
import { useAccount, useBalance } from 'wagmi';
import { useStakeContract } from '@/hooks/useStakeContract';

interface UserDashboardProps {
  className?: string;
}

export default function UserDashboard({ className = '' }: UserDashboardProps) {
  const [showBalances, setShowBalances] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  
  const { address, isConnected } = useAccount();
  
  // 获取用户ETH余额
  const { data: balance, refetch: refetchBalance } = useBalance({
    address,
  });

  // 模拟用户质押数据 - 实际应用中应该从合约聚合获取
  const userStats = {
    totalStaked: BigInt('2500000000000000000'), // 2.5 ETH
    totalRewards: BigInt('125000000000000000'), // 0.125 ETH
    pendingRewards: BigInt('25000000000000000'), // 0.025 ETH
    activeStakes: 2,
    avgAPY: 12.5,
    stakingDuration: 86400 * 30, // 30 days
  };

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await refetchBalance();
      // 这里可以添加其他数据的刷新逻辑
      await new Promise(resolve => setTimeout(resolve, 1000)); // 模拟刷新时间
    } finally {
      setIsRefreshing(false);
    }
  };

  if (!isConnected) {
    return (
      <div className={`bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 text-center ${className}`}>
        <Wallet className="w-16 h-16 mx-auto mb-4 text-gray-400" />
        <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
          连接钱包查看仪表板
        </h3>
        <p className="text-gray-500 dark:text-gray-400">
          请先连接您的钱包以查看质押统计信息
        </p>
      </div>
    );
  }

  return (
    <div className={`space-y-6 ${className}`}>
      {/* 头部统计卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* 钱包余额 */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Wallet className="w-5 h-5 text-blue-500" />
              <span className="text-sm font-medium text-gray-600 dark:text-gray-300">
                钱包余额
              </span>
            </div>
            <button
              onClick={() => setShowBalances(!showBalances)}
              className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
            >
              {showBalances ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
            </button>
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">
            {showBalances 
              ? `${formatTokenValue(balance?.value || BigInt(0))} ETH`
              : '••••••'
            }
          </p>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            可用于质押
          </p>
        </div>

        {/* 总质押金额 */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
          <div className="flex items-center gap-2 mb-4">
            <TrendingUp className="w-5 h-5 text-green-500" />
            <span className="text-sm font-medium text-gray-600 dark:text-gray-300">
              总质押金额
            </span>
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">
            {showBalances 
              ? `${formatTokenValue(userStats.totalStaked)} ETH`
              : '••••••'
            }
          </p>
          <p className="text-sm text-green-600 dark:text-green-400 mt-1">
            {userStats.activeStakes} 个活跃质押
          </p>
        </div>

        {/* 总收益 */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
          <div className="flex items-center gap-2 mb-4">
            <Gift className="w-5 h-5 text-purple-500" />
            <span className="text-sm font-medium text-gray-600 dark:text-gray-300">
              总收益
            </span>
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">
            {showBalances 
              ? `${formatTokenValue(userStats.totalRewards)} ETH`
              : '••••••'
            }
          </p>
          <p className="text-sm text-purple-600 dark:text-purple-400 mt-1">
            平均APY {formatPercentage(userStats.avgAPY)}
          </p>
        </div>

        {/* 待领取奖励 */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
          <div className="flex items-center gap-2 mb-4">
            <Clock className="w-5 h-5 text-orange-500" />
            <span className="text-sm font-medium text-gray-600 dark:text-gray-300">
              待领取奖励
            </span>
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">
            {showBalances 
              ? `${formatTokenValue(userStats.pendingRewards)} ETH`
              : '••••••'
            }
          </p>
          <button className="text-sm text-orange-600 dark:text-orange-400 mt-1 hover:underline">
            立即领取
          </button>
        </div>
      </div>

      {/* 详细信息面板 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 质押概览 */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              质押概览
            </h3>
            <button
              onClick={handleRefresh}
              disabled={isRefreshing}
              className="flex items-center gap-2 text-sm text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 disabled:opacity-50"
            >
              <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
              刷新
            </button>
          </div>

          <div className="space-y-4">
            <div className="flex justify-between items-center py-3 border-b border-gray-200 dark:border-gray-700">
              <span className="text-gray-600 dark:text-gray-300">质押时长</span>
              <span className="font-medium text-gray-900 dark:text-white">
                {formatDuration(userStats.stakingDuration)}
              </span>
            </div>
            
            <div className="flex justify-between items-center py-3 border-b border-gray-200 dark:border-gray-700">
              <span className="text-gray-600 dark:text-gray-300">平均APY</span>
              <span className="font-medium text-green-600 dark:text-green-400">
                {formatPercentage(userStats.avgAPY)}
              </span>
            </div>
            
            <div className="flex justify-between items-center py-3 border-b border-gray-200 dark:border-gray-700">
              <span className="text-gray-600 dark:text-gray-300">活跃质押池</span>
              <span className="font-medium text-gray-900 dark:text-white">
                {userStats.activeStakes}
              </span>
            </div>
            
            <div className="flex justify-between items-center py-3">
              <span className="text-gray-600 dark:text-gray-300">收益率</span>
              <span className="font-medium text-purple-600 dark:text-purple-400">
                {formatPercentage((Number(userStats.totalRewards) / Number(userStats.totalStaked)) * 100)}
              </span>
            </div>
          </div>
        </div>

        {/* 快速操作 */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">
            快速操作
          </h3>

          <div className="space-y-4">
            <button className="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-3 px-4 rounded-lg transition-colors flex items-center justify-center gap-2">
              <TrendingUp className="w-5 h-5" />
              新建质押
            </button>
            
            <button 
              disabled={userStats.pendingRewards === BigInt(0)}
              className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white font-medium py-3 px-4 rounded-lg transition-colors flex items-center justify-center gap-2"
            >
              <Gift className="w-5 h-5" />
              领取所有奖励
            </button>
            
            <button className="w-full border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 font-medium py-3 px-4 rounded-lg transition-colors flex items-center justify-center gap-2">
              <ExternalLink className="w-5 h-5" />
              查看交易历史
            </button>
          </div>

          {/* 地址信息 */}
          <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600 dark:text-gray-300">钱包地址</span>
              <button className="text-sm text-blue-600 dark:text-blue-400 hover:underline">
                复制
              </button>
            </div>
            <p className="text-sm font-mono text-gray-900 dark:text-white mt-1 break-all">
              {address}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}