'use client';

import { useState, useEffect } from 'react';
import { X, AlertCircle, Loader2 } from 'lucide-react';
import { formatTokenValue, parseTokenInput } from '@/utils/format';
import { useAccount, useBalance } from 'wagmi';
import type { PoolInfo, UserStake } from '@/types';

interface StakeModalProps {
  poolInfo: PoolInfo;
  userStake?: UserStake;
  onClose: () => void;
  mode?: 'stake' | 'unstake';
}

export default function StakeModal({ 
  poolInfo, 
  userStake, 
  onClose, 
  mode = 'stake' 
}: StakeModalProps) {
  const { address } = useAccount();
  const [amount, setAmount] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  // 获取用户ETH余额
  const { data: balance } = useBalance({
    address,
  });

  const isStakeMode = mode === 'stake';
  const title = isStakeMode ? '质押 ETH' : '解除质押';
  const buttonText = isStakeMode ? '确认质押' : '确认解除质押';
  const maxAmount = isStakeMode 
    ? balance?.value || BigInt(0)
    : userStake?.amount || BigInt(0);

  // 验证输入
  useEffect(() => {
    setError('');
    
    if (!amount) return;

    const parsedAmount = parseTokenInput(amount);
    if (parsedAmount === null) {
      setError('请输入有效的数字');
      return;
    }

    if (parsedAmount <= BigInt(0)) {
      setError('金额必须大于0');
      return;
    }

    if (parsedAmount > maxAmount) {
      setError(isStakeMode ? '余额不足' : '质押金额不足');
      return;
    }

    if (isStakeMode && parsedAmount < poolInfo.minStakeAmount) {
      setError(`最小质押金额为 ${formatTokenValue(poolInfo.minStakeAmount)} ETH`);
      return;
    }
  }, [amount, maxAmount, isStakeMode, poolInfo.minStakeAmount]);

  const handleMaxClick = () => {
    if (isStakeMode && balance) {
      // 为gas费预留一些ETH
      const reserveForGas = BigInt(1e17); // 0.1 ETH
      const availableAmount = balance.value > reserveForGas 
        ? balance.value - reserveForGas 
        : BigInt(0);
      setAmount(formatTokenValue(availableAmount, 18));
    } else if (!isStakeMode && userStake) {
      setAmount(formatTokenValue(userStake.amount, 18));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!amount || error || isLoading) return;

    const parsedAmount = parseTokenInput(amount);
    if (!parsedAmount) return;

    setIsLoading(true);
    
    try {
      if (isStakeMode) {
        // TODO: 实现质押逻辑
        console.log('Staking:', parsedAmount.toString());
      } else {
        // TODO: 实现解除质押逻辑
        console.log('Unstaking:', parsedAmount.toString());
      }
      
      // 模拟交易时间
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      onClose();
    } catch (err) {
      console.error('Transaction failed:', err);
      setError('交易失败，请重试');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-gray-800 rounded-xl max-w-md w-full p-6">
        {/* 头部 */}
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white">
            {title}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* 质押池信息 */}
        <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 mb-6">
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm text-gray-600 dark:text-gray-300">质押池</span>
            <span className="text-sm font-medium text-gray-900 dark:text-white">
              Pool #{poolInfo.id}
            </span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600 dark:text-gray-300">
              {isStakeMode ? '可用余额' : '已质押金额'}
            </span>
            <span className="text-sm font-medium text-gray-900 dark:text-white">
              {formatTokenValue(maxAmount)} ETH
            </span>
          </div>
        </div>

        {/* 输入表单 */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              {isStakeMode ? '质押金额' : '解除质押金额'}
            </label>
            <div className="relative">
              <input
                type="text"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="0.0"
                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <div className="absolute right-3 top-1/2 transform -translate-y-1/2 flex items-center gap-2">
                <button
                  type="button"
                  onClick={handleMaxClick}
                  className="text-xs bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-300 px-2 py-1 rounded hover:bg-blue-200 dark:hover:bg-blue-800"
                >
                  MAX
                </button>
                <span className="text-sm text-gray-500 dark:text-gray-400">ETH</span>
              </div>
            </div>
            {error && (
              <div className="flex items-center gap-2 mt-2 text-red-600 dark:text-red-400">
                <AlertCircle className="w-4 h-4" />
                <span className="text-sm">{error}</span>
              </div>
            )}
          </div>

          {/* 交易信息 */}
          {amount && !error && (
            <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-600 dark:text-gray-300">
                  {isStakeMode ? '质押金额' : '解除质押金额'}
                </span>
                <span className="font-medium text-gray-900 dark:text-white">
                  {amount} ETH
                </span>
              </div>
              {isStakeMode && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600 dark:text-gray-300">预计年化收益</span>
                  <span className="font-medium text-green-600 dark:text-green-400">
                    ~{((Number(poolInfo.rewardRate) * 31536000 / 1e18) * 100).toFixed(2)}%
                  </span>
                </div>
              )}
            </div>
          )}

          {/* 操作按钮 */}
          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-3 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            >
              取消
            </button>
            <button
              type="submit"
              disabled={!amount || !!error || isLoading}
              className="flex-1 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-medium py-3 px-4 rounded-lg transition-colors flex items-center justify-center gap-2"
            >
              {isLoading && <Loader2 className="w-4 h-4 animate-spin" />}
              {buttonText}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}