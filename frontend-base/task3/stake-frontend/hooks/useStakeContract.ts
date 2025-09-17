'use client';

import { useContractRead } from 'wagmi';
import { CONTRACT_ADDRESSES, STAKE_CONTRACT_ABI } from '@/constants/contracts';
import type { PoolInfo, UserStake } from '@/types';

export function useStakeContract() {
  // 读取合约状态
  const { data: poolCount } = useContractRead({
    address: CONTRACT_ADDRESSES.STAKE_CONTRACT as `0x${string}`,
    abi: STAKE_CONTRACT_ABI,
    functionName: 'poolCount',
  });

  // 获取质押池信息
  const usePoolInfo = (poolId: number) => {
    return useContractRead({
      address: CONTRACT_ADDRESSES.STAKE_CONTRACT as `0x${string}`,
      abi: STAKE_CONTRACT_ABI,
      functionName: 'pools',
      args: [BigInt(poolId)],
      enabled: poolId >= 0,
      select: (data: any): PoolInfo | undefined => {
        if (!data) return undefined;
        return {
          id: poolId,
          stakingToken: data[0],
          rewardRate: data[1],
          totalStaked: data[2],
          minStakeAmount: data[3],
          lockPeriod: data[4],
          isActive: data[5],
        };
      },
    });
  };

  // 获取用户质押信息
  const useUserStake = (userAddress: string, poolId: number) => {
    return useContractRead({
      address: CONTRACT_ADDRESSES.STAKE_CONTRACT as `0x${string}`,
      abi: STAKE_CONTRACT_ABI,
      functionName: 'userStakes',
      args: [BigInt(poolId), userAddress as `0x${string}`],
      enabled: !!userAddress && poolId >= 0,
      select: (data: any): UserStake | undefined => {
        if (!data) return undefined;
        return {
          poolId: poolId,
          amount: data[0],
          stakeTime: data[1],
          lastRewardTime: data[2],
        };
      },
    });
  };

  // 获取用户待领取奖励
  const usePendingRewards = (userAddress: string, poolId: number) => {
    return useContractRead({
      address: CONTRACT_ADDRESSES.STAKE_CONTRACT as `0x${string}`,
      abi: STAKE_CONTRACT_ABI,
      functionName: 'getPendingRewards',
      args: [BigInt(poolId), userAddress as `0x${string}`],
      enabled: !!userAddress && poolId >= 0,
    });
  };

  return {
    // 合约状态
    poolCount: Number(poolCount || 0),
    
    // 读取函数
    usePoolInfo,
    useUserStake,
    usePendingRewards,
  };
}