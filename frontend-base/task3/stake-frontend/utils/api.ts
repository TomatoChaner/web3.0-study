/**
 * API 客户端工具函数
 * 用于前端调用 Railway 部署的后端服务
 */

// 获取 API 基础 URL
const getApiUrl = (): string => {
  // 开发环境
  if (process.env.NODE_ENV === 'development') {
    return process.env.NEXT_PUBLIC_API_URL_DEV || 'http://localhost:3001';
  }
  
  // 生产环境
  return process.env.NEXT_PUBLIC_API_URL || 'https://your-railway-app.railway.app';
};

// API 客户端类
class ApiClient {
  private baseUrl: string;

  constructor() {
    this.baseUrl = getApiUrl();
  }

  // 通用请求方法
  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;
    
    const config: RequestInit = {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    };

    try {
      const response = await fetch(url, config);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error('API request failed:', error);
      throw error;
    }
  }

  // GET 请求
  async get<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'GET' });
  }

  // POST 请求
  async post<T>(endpoint: string, data?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  // PUT 请求
  async put<T>(endpoint: string, data?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  // DELETE 请求
  async delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }

  // 健康检查
  async healthCheck(): Promise<{ status: string; timestamp: string }> {
    return this.get('/health');
  }

  // 获取质押统计信息
  async getStakeStats(): Promise<any> {
    return this.get('/api/stake/stats');
  }

  // 获取用户质押信息
  async getUserStakes(address: string): Promise<any> {
    return this.get(`/api/stake/user/${address}`);
  }

  // 获取质押历史
  async getStakeHistory(address?: string): Promise<any> {
    const endpoint = address 
      ? `/api/stake/history/${address}` 
      : '/api/stake/history';
    return this.get(endpoint);
  }

  // 提交质押事件
  async submitStakeEvent(eventData: any): Promise<any> {
    return this.post('/api/stake/events', eventData);
  }
}

// 创建单例实例
export const apiClient = new ApiClient();

// 导出类型定义
export interface StakeStats {
  totalStaked: string;
  totalUsers: number;
  totalRewards: string;
  apy: number;
}

export interface UserStake {
  address: string;
  amount: string;
  timestamp: number;
  rewards: string;
  isActive: boolean;
}

export interface StakeEvent {
  txHash: string;
  address: string;
  amount: string;
  type: 'stake' | 'unstake' | 'claim';
  timestamp: number;
  blockNumber: number;
}

// 便捷的 API 调用函数
export const api = {
  // 健康检查
  healthCheck: () => apiClient.healthCheck(),
  
  // 质押相关
  getStakeStats: () => apiClient.getStakeStats(),
  getUserStakes: (address: string) => apiClient.getUserStakes(address),
  getStakeHistory: (address?: string) => apiClient.getStakeHistory(address),
  submitStakeEvent: (eventData: StakeEvent) => apiClient.submitStakeEvent(eventData),
};

export default apiClient;