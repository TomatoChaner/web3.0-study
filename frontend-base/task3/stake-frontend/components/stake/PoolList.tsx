'use client';

import { useState } from 'react';
import { Search, Filter, TrendingUp, TrendingDown } from 'lucide-react';
import PoolCard from './PoolCard';

interface PoolListProps {
  className?: string;
}

type SortOption = 'apy' | 'tvl' | 'rewards' | 'newest';
type FilterOption = 'all' | 'active' | 'paused';

export default function PoolList({ className = '' }: PoolListProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState<SortOption>('apy');
  const [filterBy, setFilterBy] = useState<FilterOption>('all');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  // 模拟质押池数据 - 实际应用中应该从合约获取
  const poolIds = [0, 1, 2]; // 假设有3个质押池

  const handleSortChange = (newSort: SortOption) => {
    if (sortBy === newSort) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(newSort);
      setSortOrder('desc');
    }
  };

  return (
    <div className={`space-y-6 ${className}`}>
      {/* 搜索和筛选栏 */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
        <div className="flex flex-col lg:flex-row gap-4">
          {/* 搜索框 */}
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="搜索质押池..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>

          {/* 筛选器 */}
          <div className="flex gap-3">
            {/* 状态筛选 */}
            <select
              value={filterBy}
              onChange={(e) => setFilterBy(e.target.value as FilterOption)}
              className="px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">全部状态</option>
              <option value="active">活跃中</option>
              <option value="paused">已暂停</option>
            </select>

            {/* 排序选择 */}
            <div className="flex">
              <select
                value={sortBy}
                onChange={(e) => handleSortChange(e.target.value as SortOption)}
                className="px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-l-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent border-r-0"
              >
                <option value="apy">按收益率</option>
                <option value="tvl">按总锁仓</option>
                <option value="rewards">按奖励</option>
                <option value="newest">按时间</option>
              </select>
              <button
                onClick={() => setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')}
                className="px-3 py-3 border border-gray-300 dark:border-gray-600 rounded-r-lg bg-white dark:bg-gray-700 text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                {sortOrder === 'desc' ? (
                  <TrendingDown className="w-5 h-5" />
                ) : (
                  <TrendingUp className="w-5 h-5" />
                )}
              </button>
            </div>
          </div>
        </div>

        {/* 快速筛选标签 */}
        <div className="flex flex-wrap gap-2 mt-4">
          <button
            onClick={() => setFilterBy('all')}
            className={`px-3 py-1 rounded-full text-sm transition-colors ${
              filterBy === 'all'
                ? 'bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600'
            }`}
          >
            全部
          </button>
          <button
            onClick={() => setFilterBy('active')}
            className={`px-3 py-1 rounded-full text-sm transition-colors ${
              filterBy === 'active'
                ? 'bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600'
            }`}
          >
            活跃中
          </button>
          <button
            onClick={() => setFilterBy('paused')}
            className={`px-3 py-1 rounded-full text-sm transition-colors ${
              filterBy === 'paused'
                ? 'bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600'
            }`}
          >
            已暂停
          </button>
        </div>
      </div>

      {/* 质押池列表 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
        {poolIds.map((poolId) => (
          <PoolCard
            key={poolId}
            poolId={poolId}
            className="h-full"
          />
        ))}
      </div>

      {/* 空状态 */}
      {poolIds.length === 0 && (
        <div className="text-center py-12">
          <div className="w-16 h-16 mx-auto mb-4 bg-gray-100 dark:bg-gray-700 rounded-full flex items-center justify-center">
            <Filter className="w-8 h-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
            没有找到质押池
          </h3>
          <p className="text-gray-500 dark:text-gray-400">
            尝试调整搜索条件或筛选器
          </p>
        </div>
      )}
    </div>
  );
}