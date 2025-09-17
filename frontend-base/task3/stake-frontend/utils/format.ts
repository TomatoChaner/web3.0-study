import { formatEther, formatUnits, parseEther, parseUnits } from 'viem';

/**
 * 格式化以太币数量
 * @param value - 以wei为单位的值
 * @param decimals - 小数位数，默认4位
 * @returns 格式化后的字符串
 */
export function formatEtherValue(value: bigint, decimals: number = 4): string {
  const formatted = formatEther(value);
  const num = parseFloat(formatted);
  return num.toFixed(decimals);
}

/**
 * 格式化代币数量
 * @param value - 代币数量（最小单位）
 * @param tokenDecimals - 代币精度
 * @param displayDecimals - 显示小数位数
 * @returns 格式化后的字符串
 */
export function formatTokenValue(
  value: bigint,
  tokenDecimals: number = 18,
  displayDecimals: number = 4
): string {
  const formatted = formatUnits(value, tokenDecimals);
  const num = parseFloat(formatted);
  return num.toFixed(displayDecimals);
}

/**
 * 格式化大数字（添加千分位分隔符）
 * @param value - 数值
 * @param decimals - 小数位数
 * @returns 格式化后的字符串
 */
export function formatNumber(value: number | string, decimals: number = 2): string {
  const num = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(num)) return '0';
  
  return new Intl.NumberFormat('zh-CN', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(num);
}

/**
 * 格式化百分比
 * @param value - 数值（0-1之间或0-100之间）
 * @param isDecimal - 是否为小数形式（0-1），默认false
 * @param decimals - 小数位数
 * @returns 格式化后的百分比字符串
 */
export function formatPercentage(
  value: number,
  isDecimal: boolean = false,
  decimals: number = 2
): string {
  const percentage = isDecimal ? value * 100 : value;
  return `${percentage.toFixed(decimals)}%`;
}

/**
 * 格式化时间戳为可读日期
 * @param timestamp - 时间戳（秒）
 * @param includeTime - 是否包含时间，默认true
 * @returns 格式化后的日期字符串
 */
export function formatTimestamp(timestamp: bigint | number, includeTime: boolean = true): string {
  const date = new Date(Number(timestamp) * 1000);
  
  const options: Intl.DateTimeFormatOptions = {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    timeZone: 'Asia/Shanghai',
  };
  
  if (includeTime) {
    options.hour = '2-digit';
    options.minute = '2-digit';
    options.second = '2-digit';
  }
  
  return new Intl.DateTimeFormat('zh-CN', options).format(date);
}

/**
 * 格式化持续时间
 * @param seconds - 秒数
 * @returns 格式化后的持续时间字符串
 */
export function formatDuration(seconds: bigint | number): string {
  const totalSeconds = Number(seconds);
  
  const days = Math.floor(totalSeconds / (24 * 60 * 60));
  const hours = Math.floor((totalSeconds % (24 * 60 * 60)) / (60 * 60));
  const minutes = Math.floor((totalSeconds % (60 * 60)) / 60);
  const remainingSeconds = totalSeconds % 60;
  
  const parts: string[] = [];
  
  if (days > 0) parts.push(`${days}天`);
  if (hours > 0) parts.push(`${hours}小时`);
  if (minutes > 0) parts.push(`${minutes}分钟`);
  if (remainingSeconds > 0 || parts.length === 0) {
    parts.push(`${remainingSeconds}秒`);
  }
  
  return parts.slice(0, 2).join(' '); // 只显示最大的两个单位
}

/**
 * 格式化地址（显示前6位和后4位）
 * @param address - 以太坊地址
 * @param startLength - 开始显示的字符数，默认6
 * @param endLength - 结尾显示的字符数，默认4
 * @returns 格式化后的地址字符串
 */
export function formatAddress(
  address: string,
  startLength: number = 6,
  endLength: number = 4
): string {
  if (!address || address.length < startLength + endLength) {
    return address;
  }
  
  return `${address.slice(0, startLength)}...${address.slice(-endLength)}`;
}

/**
 * 格式化交易哈希
 * @param hash - 交易哈希
 * @returns 格式化后的哈希字符串
 */
export function formatTxHash(hash: string): string {
  return formatAddress(hash, 8, 6);
}

/**
 * 格式化APY
 * @param rewardRate - 奖励率（每秒）
 * @param decimals - 小数位数
 * @returns APY百分比
 */
export function formatAPY(rewardRate: bigint, decimals: number = 2): string {
  // 计算年化收益率：rewardRate * 365 * 24 * 60 * 60 * 100
  const secondsPerYear = 365 * 24 * 60 * 60;
  const apy = Number(rewardRate) * secondsPerYear * 100;
  return formatPercentage(apy, false, decimals);
}

/**
 * 解析用户输入的数字
 * @param input - 用户输入
 * @param decimals - 代币精度
 * @returns 解析后的bigint值
 */
export function parseTokenInput(input: string, decimals: number = 18): bigint {
  try {
    // 移除空格和非数字字符（除了小数点）
    const cleaned = input.replace(/[^\d.]/g, '');
    if (!cleaned || cleaned === '.') return BigInt(0);
    
    return parseUnits(cleaned, decimals);
  } catch (error) {
    return BigInt(0);
  }
}

/**
 * 验证数字输入
 * @param input - 用户输入
 * @param min - 最小值
 * @param max - 最大值
 * @returns 验证结果
 */
export function validateNumberInput(
  input: string,
  min?: number,
  max?: number
): { isValid: boolean; error?: string } {
  const cleaned = input.replace(/[^\d.]/g, '');
  
  if (!cleaned || cleaned === '.') {
    return { isValid: false, error: '请输入有效数字' };
  }
  
  const num = parseFloat(cleaned);
  
  if (isNaN(num)) {
    return { isValid: false, error: '请输入有效数字' };
  }
  
  if (min !== undefined && num < min) {
    return { isValid: false, error: `最小值为 ${min}` };
  }
  
  if (max !== undefined && num > max) {
    return { isValid: false, error: `最大值为 ${max}` };
  }
  
  return { isValid: true };
}

/**
 * 格式化文件大小
 * @param bytes - 字节数
 * @returns 格式化后的文件大小字符串
 */
export function formatFileSize(bytes: number): string {
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  if (bytes === 0) return '0 B';
  
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(2)} ${sizes[i]}`;
}

/**
 * 格式化相对时间
 * @param timestamp - 时间戳（秒）
 * @returns 相对时间字符串
 */
export function formatRelativeTime(timestamp: bigint | number): string {
  const now = Date.now() / 1000;
  const time = Number(timestamp);
  const diff = now - time;
  
  if (diff < 60) return '刚刚';
  if (diff < 3600) return `${Math.floor(diff / 60)}分钟前`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}小时前`;
  if (diff < 2592000) return `${Math.floor(diff / 86400)}天前`;
  if (diff < 31536000) return `${Math.floor(diff / 2592000)}个月前`;
  
  return `${Math.floor(diff / 31536000)}年前`;
}

/**
 * 截断文本
 * @param text - 文本
 * @param maxLength - 最大长度
 * @param suffix - 后缀，默认为'...'
 * @returns 截断后的文本
 */
export function truncateText(text: string, maxLength: number, suffix: string = '...'): string {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength - suffix.length) + suffix;
}