// 质押池信息类型
export interface PoolInfo {
  id: number;
  stakingToken: `0x${string}`;
  rewardRate: bigint;
  totalStaked: bigint;
  minStakeAmount: bigint;
  lockPeriod: bigint;
  isActive: boolean;
  tokenSymbol?: string;
  tokenName?: string;
  tokenDecimals?: number;
  apy?: number;
}

// 用户质押信息类型
export interface UserStake {
  poolId: number;
  amount: bigint;
  stakeTime: bigint;
  lastRewardTime: bigint;
  pendingRewards?: bigint;
}

// 解质押请求类型
export interface UnstakeRequest {
  poolId: number;
  amount: bigint;
  requestTime: bigint;
  canWithdraw?: boolean;
  timeRemaining?: bigint;
}

// 用户仪表板数据类型
export interface UserDashboard {
  totalStaked: bigint;
  totalRewards: bigint;
  activeStakes: UserStake[];
  unstakeRequests: UnstakeRequest[];
  claimableRewards: bigint;
}

// 交易状态类型
export type TransactionStatus = 'idle' | 'pending' | 'success' | 'error';

// 交易类型
export type TransactionType = 'stake' | 'unstake' | 'claim' | 'withdraw' | 'approve';

// 交易信息类型
export interface TransactionInfo {
  type: TransactionType;
  status: TransactionStatus;
  hash?: string;
  error?: string;
  poolId?: number;
  amount?: bigint;
}

// 钱包状态类型
export interface WalletState {
  isConnected: boolean;
  address?: `0x${string}`;
  chainId?: number;
  balance?: bigint;
  isCorrectNetwork: boolean;
}

// 合约状态类型
export interface ContractState {
  isLoading: boolean;
  error?: string;
  emergencyWithdrawEnabled: boolean;
}

// 表单数据类型
export interface StakeFormData {
  poolId: number;
  amount: string;
  isValid: boolean;
  error?: string;
}

export interface UnstakeFormData {
  poolId: number;
  amount: string;
  isValid: boolean;
  error?: string;
}

// API 响应类型
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

// 分页类型
export interface Pagination {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

// 排序类型
export interface SortConfig {
  field: string;
  direction: 'asc' | 'desc';
}

// 过滤器类型
export interface FilterConfig {
  isActive?: boolean;
  minApy?: number;
  maxApy?: number;
  hasUserStake?: boolean;
}

// 统计数据类型
export interface StatsData {
  totalValueLocked: bigint;
  totalUsers: number;
  totalPools: number;
  averageApy: number;
  totalRewardsDistributed: bigint;
}

// 历史记录类型
export interface HistoryRecord {
  id: string;
  type: TransactionType;
  poolId: number;
  amount: bigint;
  timestamp: bigint;
  txHash: string;
  status: 'success' | 'failed';
  blockNumber?: number;
}

// 通知类型
export interface Notification {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  title: string;
  message: string;
  timestamp: number;
  isRead: boolean;
  action?: {
    label: string;
    onClick: () => void;
  };
}

// 主题类型
export type Theme = 'light' | 'dark' | 'system';

// 语言类型
export type Language = 'zh-CN' | 'en-US';

// 应用设置类型
export interface AppSettings {
  theme: Theme;
  language: Language;
  notifications: {
    enabled: boolean;
    sound: boolean;
    desktop: boolean;
  };
  privacy: {
    analytics: boolean;
    crashReports: boolean;
  };
}

// 错误类型
export interface AppError {
  code: string;
  message: string;
  details?: any;
  timestamp: number;
}

// 加载状态类型
export interface LoadingState {
  [key: string]: boolean;
}

// 模态框状态类型
export interface ModalState {
  isOpen: boolean;
  type?: 'stake' | 'unstake' | 'claim' | 'withdraw' | 'settings';
  data?: any;
}

// 表格列配置类型
export interface TableColumn<T> {
  key: keyof T;
  label: string;
  sortable?: boolean;
  render?: (value: any, record: T) => React.ReactNode;
  width?: string;
  align?: 'left' | 'center' | 'right';
}

// 图表数据类型
export interface ChartDataPoint {
  timestamp: number;
  value: number;
  label?: string;
}

export interface ChartData {
  labels: string[];
  datasets: {
    label: string;
    data: number[];
    borderColor?: string;
    backgroundColor?: string;
    fill?: boolean;
  }[];
}

// 所有类型已通过interface和type声明导出