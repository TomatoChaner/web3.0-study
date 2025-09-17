'use client';

import { useState } from 'react';
import { Coins, TrendingUp, Clock, Users, Lock, AlertCircle } from 'lucide-react';
import { formatTokenValue, formatPercentage, formatDuration, formatNumber } from '../../utils/format';
import { useAccount } from 'wagmi';
import { useStakeContract } from '../../hooks/useStakeContract';
import StakeModal from './StakeModal';
import type { PoolInfo } from '../../types';

interface PoolCardProps {
  poolId: number;
  className?: string;
}

export default function PoolCard({ poolId, className = '' }: PoolCardProps) {
  const [showStakeModal, setShowStakeModal] = useState(false);
  const [showUnstakeModal, setShowUnstakeModal] = useState(false);
  const { address } = useAccount();
  const { getPoolInfo, getUserStakeInfo, isLoading, error } = useStakeContract();
  
  // 获取池子信息
  const poolInfo = getPoolInfo();
  const userStake = address ? getUserStakeInfo(address) : null;
  
  // 模拟待领取奖励（实际应该从合约获取）
  const pendingRewards = userStake ? userStake.rewardDebt : BigInt(0);
  const poolLoading = isLoading;
  const userStakeLoading = isLoading;
  const rewardsLoading = isLoading;

  if (poolLoading) {
    return (
      <div className={`bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 ${className}`}>
        <div className="animate-pulse">
          <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded mb-4"></div>
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-2"></div>
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-2"></div>
          <div className="h-10 bg-gray-200 dark:bg-gray-700 rounded mt-4"></div>
        </div>
      </div>
    );
  }

  if (!poolInfo) {
    return (
      <div className={`bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 ${className}`}>
        <div className="text-center text-gray-500 dark:text-gray-400">
          <AlertCircle className="w-12 h-12 mx-auto mb-2" />
          <p>质押池信息加载失败</p>
        </div>
      </div>
    );
  }

  // 计算APY（简化计算）
  const calculateAPY = () => {
    if (!poolInfo.rewardRate || !poolInfo.totalStaked || poolInfo.totalStaked === BigInt(0)) {
      return 0;
    }
    // 简化的APY计算：(rewardRate * 365 * 24 * 60 * 60) / totalStaked * 100
    const yearlyRewards = Number(poolInfo.rewardRate) * 365 * 24 * 60 * 60;
    const apy = (yearlyRewards / Number(poolInfo.totalStaked)) * 100;
    return apy;
  };

  const apy = calculateAPY();
  const hasUserStake = userStake && userStake.amount > BigInt(0);
  const userStakeAmount = hasUserStake ? Number(userStake.amount) / 1e18 : 0;
  const pendingRewardsAmount = pendingRewards ? Number(pendingRewards) / 1e18 : 0;

  return (
    <>
      <div className={`bg-white dark:bg-gray-800 rounded-xl shadow-lg hover:shadow-xl transition-all duration-300 border border-gray-200 dark:border-gray-700 ${className}`}>
        {/* 头部 */}
        <div className="p-6 border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full flex items-center justify-center">
                <Coins className="w-6 h-6 text-white" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                  质押池 #{poolId}
                </h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {poolInfo.isActive ? '活跃' : '已暂停'}
                </p>
              </div>
            </div>
            
            {/* 状态指示器 */}
            <div className={`px-3 py-1 rounded-full text-xs font-medium ${
              poolInfo.isActive 
                ? 'bg-green-100 text-green-600 dark:bg-green-900/20 dark:text-green-400'
                : 'bg-red-100 text-red-600 dark:bg-red-900/20 dark:text-red-400'
            }`}>
              {poolInfo.isActive ? '活跃' : '暂停'}
            </div>
          </div>

          {/* APY显示 */}
          <div className="flex items-center gap-2 mb-2">
            <TrendingUp className="w-5 h-5 text-green-500" />
            <span className="text-2xl font-bold text-green-500">
              {formatPercentage(apy, false, 2)}
            </span>
            <span className="text-sm text-gray-500 dark:text-gray-400">APY</span>
          </div>
        </div>

        {/* 统计信息 */}
        <div className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
                <Users className="w-4 h-4" />
                <span>总质押量</span>
              </div>
              <p className="text-lg font-semibold text-gray-900 dark:text-white">
                {formatNumber(Number(poolInfo.totalStaked) / 1e18)} ETH
              </p>
            </div>

            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
                <Clock className="w-4 h-4" />
                <span>锁定期</span>
              </div>
              <p className="text-lg font-semibold text-gray-900 dark:text-white">
                {formatDuration(0)}
              </p>
            </div>

            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
                <Lock className="w-4 h-4" />
                <span>最小质押</span>
              </div>
              <p className="text-lg font-semibold text-gray-900 dark:text-white">
                {formatNumber(Number(poolInfo.minStakeAmount) / 1e18)} ETH
              </p>
            </div>

            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
                <TrendingUp className="w-4 h-4" />
                <span>奖励率</span>
              </div>
              <p className="text-lg font-semibold text-gray-900 dark:text-white">
                {formatNumber(Number(poolInfo.rewardRate) / 1e18)} ETH/秒
              </p>
            </div>
          </div>

          {/* 用户质押信息 */}
          {address && hasUserStake && (
            <div className="mt-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
              <h4 className="text-sm font-medium text-blue-900 dark:text-blue-100 mb-3">
                我的质押
              </h4>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-xs text-blue-600 dark:text-blue-400">质押数量</p>
                  <p className="text-lg font-semibold text-blue-900 dark:text-blue-100">
                    {formatNumber(userStakeAmount)} ETH
                  </p>
                </div>
                <div>
                  <p className="text-xs text-blue-600 dark:text-blue-400">待领取奖励</p>
                  <p className="text-lg font-semibold text-blue-900 dark:text-blue-100">
                    {rewardsLoading ? '...' : formatNumber(pendingRewardsAmount)} ETH
                  </p>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* 操作按钮 */}
        <div className="p-6 border-t border-gray-200 dark:border-gray-700">
          {!address ? (
            <p className="text-center text-gray-500 dark:text-gray-400 text-sm">
              请先连接钱包
            </p>
          ) : !poolInfo.isActive ? (
            <p className="text-center text-red-500 text-sm">
              质押池已暂停
            </p>
          ) : (
            <div className="flex gap-3">
              <button
                onClick={() => setShowStakeModal(true)}
                className="flex-1 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200 transform hover:scale-105"
              >
                {hasUserStake ? '增加质押' : '开始质押'}
              </button>
              
              {hasUserStake && (
                <button
                  onClick={() => setShowStakeModal(true)}
                  className="flex-1 bg-gray-600 hover:bg-gray-700 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200"
                >
                  管理质押
                </button>
              )}
            </div>
          )}
        </div>
      </div>

      {/* 质押模态框 */}
      {showStakeModal && (
        <StakeModal
          poolInfo={poolInfo}
          userStake={userStake}
          mode="stake"
          onClose={() => setShowStakeModal(false)}
        />
      )}

      {/* 解除质押模态框 */}
      {showUnstakeModal && (
        <StakeModal
          poolInfo={poolInfo}
          userStake={userStake}
          mode="unstake"
          onClose={() => setShowUnstakeModal(false)}
        />
      )}
    </>
  );
}