'use client';

import { useState } from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';
import UserDashboard from '@/components/dashboard/UserDashboard';
import PoolList from '@/components/stake/PoolList';

export default function Home() {
  const { isConnected } = useAccount();
  const [activeTab, setActiveTab] = useState('pools');

  return (
    <main className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-8">
        {/* 头部 */}
        <header className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
              ETH 质押平台
            </h1>
            <p className="text-gray-600 dark:text-gray-300 mt-2">
              安全、透明的以太坊质押服务
            </p>
          </div>
          <ConnectButton />
        </header>

        {/* 全局统计 */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
            平台统计
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                12.5%
              </div>
              <div className="text-sm text-gray-600 dark:text-gray-300">
                平均APY
              </div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600 dark:text-green-400">
                1,234 ETH
              </div>
              <div className="text-sm text-gray-600 dark:text-gray-300">
                总锁仓量
              </div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-600 dark:text-purple-400">
                456
              </div>
              <div className="text-sm text-gray-600 dark:text-gray-300">
                活跃用户
              </div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-600 dark:text-orange-400">
                3
              </div>
              <div className="text-sm text-gray-600 dark:text-gray-300">
                质押池数量
              </div>
            </div>
          </div>
        </div>

        {/* 主要内容区域 */}
        {isConnected ? (
          <div className="space-y-6">
            {/* 标签页导航 */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-1">
              <div className="flex space-x-1">
                <button
                  onClick={() => setActiveTab('dashboard')}
                  className={`flex-1 py-3 px-4 rounded-lg font-medium transition-colors ${
                    activeTab === 'dashboard'
                      ? 'bg-blue-600 text-white'
                      : 'text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
                  }`}
                >
                  我的仪表板
                </button>
                <button
                  onClick={() => setActiveTab('pools')}
                  className={`flex-1 py-3 px-4 rounded-lg font-medium transition-colors ${
                    activeTab === 'pools'
                      ? 'bg-blue-600 text-white'
                      : 'text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
                  }`}
                >
                  质押池
                </button>
              </div>
            </div>

            {/* 标签页内容 */}
            {activeTab === 'dashboard' && <UserDashboard />}
            {activeTab === 'pools' && <PoolList />}
          </div>
        ) : (
          <div className="text-center py-16">
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 max-w-md mx-auto">
              <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">
                欢迎来到 ETH 质押平台
              </h2>
              <p className="text-gray-600 dark:text-gray-300 mb-6">
                连接您的钱包开始质押，获得稳定的收益回报
              </p>
              <div className="space-y-4">
                <div className="flex items-center justify-between py-2">
                  <span className="text-gray-600 dark:text-gray-300">✨ 高收益率</span>
                  <span className="font-medium text-green-600 dark:text-green-400">最高 15% APY</span>
                </div>
                <div className="flex items-center justify-between py-2">
                  <span className="text-gray-600 dark:text-gray-300">🔒 安全可靠</span>
                  <span className="font-medium text-blue-600 dark:text-blue-400">智能合约保护</span>
                </div>
                <div className="flex items-center justify-between py-2">
                  <span className="text-gray-600 dark:text-gray-300">⚡ 随时提取</span>
                  <span className="font-medium text-purple-600 dark:text-purple-400">灵活操作</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </main>
  );
}