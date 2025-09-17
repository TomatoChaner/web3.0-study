'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';
import { Wallet, TrendingUp, Clock, Award } from 'lucide-react';

import { useStakeContract } from '../../hooks/useStakeContract';

export default function UserDashboard() {
  const { address, isConnected } = useAccount();
  const { getUserStakeInfo, isLoading } = useStakeContract();

  if (!isConnected || !address) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
        <div className="text-center text-gray-500 dark:text-gray-400">
          <Wallet className="w-12 h-12 mx-auto mb-4" />
          <h3 className="text-lg font-semibold mb-2">连接钱包</h3>
          <p>请连接您的钱包以查看质押信息</p>
        </div>
      </div>
    );
  }

  const userStake = getUserStakeInfo(address);
  const stakedAmount = Number(userStake.amount) / 1e18;
  const pendingRewards = Number(userStake.rewardDebt) / 1e18;

  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
      <div className="flex items-center gap-3 mb-6">
        <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full flex items-center justify-center">
          <Wallet className="w-5 h-5 text-white" />
        </div>
        <div>
          <h2 className="text-xl font-bold text-gray-900 dark:text-white">我的仪表板</h2>
          <p className="text-sm text-gray-500 dark:text-gray-400">质押概览</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* 总质押量 */}
        <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
          <div className="flex items-center gap-3 mb-2">
            <TrendingUp className="w-5 h-5 text-blue-600 dark:text-blue-400" />
            <span className="text-sm font-medium text-blue-600 dark:text-blue-400">总质押量</span>
          </div>
          <p className="text-2xl font-bold text-blue-900 dark:text-blue-100">
            {stakedAmount.toFixed(4)} ETH
          </p>
          <p className="text-xs text-blue-600 dark:text-blue-400 mt-1">
            ≈ ${(stakedAmount * 2000).toFixed(2)} USD
          </p>
        </div>

        {/* 待领取奖励 */}
        <div className="bg-green-50 dark:bg-green-900/20 rounded-lg p-4 border border-green-200 dark:border-green-800">
          <div className="flex items-center gap-3 mb-2">
            <Award className="w-5 h-5 text-green-600 dark:text-green-400" />
            <span className="text-sm font-medium text-green-600 dark:text-green-400">待领取奖励</span>
          </div>
          <p className="text-2xl font-bold text-green-900 dark:text-green-100">
            {pendingRewards.toFixed(4)} ETH
          </p>
          <p className="text-xs text-green-600 dark:text-green-400 mt-1">
            ≈ ${(pendingRewards * 2000).toFixed(2)} USD
          </p>
        </div>

        {/* 质押时长 */}
        <div className="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-4 border border-purple-200 dark:border-purple-800">
          <div className="flex items-center gap-3 mb-2">
            <Clock className="w-5 h-5 text-purple-600 dark:text-purple-400" />
            <span className="text-sm font-medium text-purple-600 dark:text-purple-400">质押时长</span>
          </div>
          <p className="text-2xl font-bold text-purple-900 dark:text-purple-100">
            {Math.floor((Date.now() - Number(userStake.lastStakeTime)) / (1000 * 60 * 60 * 24))} 天
          </p>
          <p className="text-xs text-purple-600 dark:text-purple-400 mt-1">
            自上次质押
          </p>
        </div>
      </div>

      {/* 操作按钮 */}
      {stakedAmount > 0 && (
        <div className="mt-6 flex gap-3">
          <button className="flex-1 bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200">
            领取奖励
          </button>
          <button className="flex-1 bg-gray-600 hover:bg-gray-700 text-white font-medium py-3 px-4 rounded-lg transition-all duration-200">
            管理质押
          </button>
        </div>
      )}
    </div>
  );
}