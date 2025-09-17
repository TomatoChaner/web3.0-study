/**
 * API 调用 React Hook
 * 提供便捷的 API 调用和状态管理
 */

import { useState, useEffect, useCallback } from 'react';
import { api, StakeStats, UserStake, StakeEvent } from '@/utils/api';

// 通用 API Hook
export function useApi<T>(
  apiCall: () => Promise<T>,
  dependencies: any[] = []
) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const result = await apiCall();
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }, dependencies);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}

// 健康检查 Hook
export function useHealthCheck() {
  return useApi(() => api.healthCheck());
}

// 质押统计 Hook
export function useStakeStats() {
  return useApi<StakeStats>(() => api.getStakeStats());
}

// 用户质押信息 Hook
export function useUserStakes(address: string | undefined) {
  return useApi<UserStake[]>(
    () => address ? api.getUserStakes(address) : Promise.resolve([]),
    [address]
  );
}

// 质押历史 Hook
export function useStakeHistory(address?: string) {
  return useApi<StakeEvent[]>(
    () => api.getStakeHistory(address),
    [address]
  );
}

// 提交质押事件 Hook
export function useSubmitStakeEvent() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submitEvent = useCallback(async (eventData: StakeEvent) => {
    try {
      setLoading(true);
      setError(null);
      const result = await api.submitStakeEvent(eventData);
      return result;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      setError(errorMessage);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  return { submitEvent, loading, error };
}

// 后端连接状态 Hook
export function useBackendConnection() {
  const [isConnected, setIsConnected] = useState(false);
  const [lastChecked, setLastChecked] = useState<Date | null>(null);

  const checkConnection = useCallback(async () => {
    try {
      await api.healthCheck();
      setIsConnected(true);
    } catch (error) {
      setIsConnected(false);
    } finally {
      setLastChecked(new Date());
    }
  }, []);

  useEffect(() => {
    checkConnection();
    
    // 每30秒检查一次连接状态
    const interval = setInterval(checkConnection, 30000);
    
    return () => clearInterval(interval);
  }, [checkConnection]);

  return { isConnected, lastChecked, checkConnection };
}