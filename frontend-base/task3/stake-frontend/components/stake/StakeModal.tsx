'use client';

import { useState } from 'react';
import { X, AlertCircle, Loader2 } from 'lucide-react';
import { formatEtherValue } from '../../utils/format';

interface StakeModalProps {
  isOpen: boolean;
  onClose: () => void;
  mode: 'stake' | 'unstake';
  poolName: string;
  userBalance?: bigint;
  stakedAmount?: bigint;
  onStake?: (amount: string) => Promise<void>;
  onUnstake?: (amount: string) => Promise<void>;
}

export default function StakeModal({
  isOpen,
  onClose,
  mode,
  poolName,
  userBalance = BigInt(0),
  stakedAmount = BigInt(0),
  onStake,
  onUnstake
}: StakeModalProps) {
  const [amount, setAmount] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  if (!isOpen) return null;

  const maxAmount = mode === 'stake' ? userBalance : stakedAmount;
  const isValidAmount = amount && parseFloat(amount) > 0 && parseFloat(amount) <= parseFloat(formatEtherValue(maxAmount));

  const handleSubmit = async () => {
    if (!isValidAmount) return;

    setIsLoading(true);
    setError('');

    try {
      if (mode === 'stake' && onStake) {
        await onStake(amount);
      } else if (mode === 'unstake' && onUnstake) {
        await onUnstake(amount);
      }
      onClose();
      setAmount('');
    } catch (err) {
      setError(err instanceof Error ? err.message : '操作失败');
    } finally {
      setIsLoading(false);
    }
  };

  const setMaxAmount = () => {
    setAmount(formatEtherValue(maxAmount));
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md mx-4">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold">
            {mode === 'stake' ? '质押' : '取消质押'} {poolName}
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              {mode === 'stake' ? '质押数量' : '取消质押数量'}
            </label>
            <div className="relative">
              <input
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="0.0"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                disabled={isLoading}
              />
              <button
                onClick={setMaxAmount}
                className="absolute right-2 top-1/2 transform -translate-y-1/2 text-blue-500 text-sm hover:text-blue-600"
                disabled={isLoading}
              >
                最大
              </button>
            </div>
          </div>

          <div className="text-sm text-gray-600">
            <div className="flex justify-between">
              <span>可用余额:</span>
              <span>{formatEtherValue(maxAmount)} ETH</span>
            </div>
          </div>

          {error && (
            <div className="flex items-center space-x-2 text-red-600 text-sm">
              <AlertCircle className="w-4 h-4" />
              <span>{error}</span>
            </div>
          )}

          <div className="flex space-x-3">
            <button
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              disabled={isLoading}
            >
              取消
            </button>
            <button
              onClick={handleSubmit}
              disabled={!isValidAmount || isLoading}
              className="flex-1 px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 disabled:bg-gray-300 disabled:cursor-not-allowed flex items-center justify-center"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  处理中...
                </>
              ) : (
                mode === 'stake' ? '质押' : '取消质押'
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}