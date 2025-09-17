/**
 * 后端连接状态组件
 * 显示前后端连接状态和API测试
 */

'use client';

import { useState, useEffect } from 'react';
import { useBackendConnection, useHealthCheck } from '@/hooks/useApi';

export default function BackendStatus() {
  const { isConnected, lastChecked, checkConnection } = useBackendConnection();
  const { data: healthData, loading, error, refetch } = useHealthCheck();
  const [testResult, setTestResult] = useState<string>('');
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
  }, []);

  const handleTestConnection = async () => {
    setTestResult('测试中...');
    try {
      await checkConnection();
      await refetch();
      setTestResult('✅ 连接测试成功');
    } catch (err) {
      setTestResult(`❌ 连接测试失败: ${err instanceof Error ? err.message : '未知错误'}`);
    }
  };

  const getStatusColor = () => {
    if (loading) return 'text-yellow-500';
    if (isConnected) return 'text-green-500';
    return 'text-red-500';
  };

  const getStatusText = () => {
    if (loading) return '检查中...';
    if (isConnected) return '已连接';
    return '连接失败';
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6 mb-6">
      <h3 className="text-lg font-semibold mb-4">后端服务状态</h3>
      
      {/* 连接状态 */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-2">
          <div className={`w-3 h-3 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`}></div>
          <span className={`font-medium ${getStatusColor()}`}>
            {getStatusText()}
          </span>
        </div>
        
        <button
          onClick={handleTestConnection}
          disabled={loading}
          className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50"
        >
          测试连接
        </button>
      </div>

      {/* API URL */}
      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-1">
          API 地址:
        </label>
        <code className="block p-2 bg-gray-100 rounded text-sm">
          {isClient ? (
            process.env.NODE_ENV === 'development' 
              ? process.env.NEXT_PUBLIC_API_URL_DEV || 'http://localhost:3001'
              : process.env.NEXT_PUBLIC_API_URL || 'https://your-railway-app.railway.app'
          ) : (
            '加载中...'
          )}
        </code>
      </div>

      {/* 健康检查数据 */}
      {healthData && (
        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            健康检查响应:
          </label>
          <pre className="p-2 bg-gray-100 rounded text-sm overflow-x-auto">
            {JSON.stringify(healthData, null, 2)}
          </pre>
        </div>
      )}

      {/* 错误信息 */}
      {error && (
        <div className="mb-4">
          <label className="block text-sm font-medium text-red-700 mb-1">
            错误信息:
          </label>
          <div className="p-2 bg-red-100 text-red-700 rounded text-sm">
            {error}
          </div>
        </div>
      )}

      {/* 测试结果 */}
      {testResult && (
        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            测试结果:
          </label>
          <div className="p-2 bg-gray-100 rounded text-sm">
            {testResult}
          </div>
        </div>
      )}

      {/* 最后检查时间 */}
      {lastChecked && isClient && (
        <div className="text-xs text-gray-500">
          最后检查: {lastChecked.toLocaleString()}
        </div>
      )}

      {/* 配置说明 */}
      <div className="mt-4 p-3 bg-blue-50 rounded">
        <h4 className="text-sm font-medium text-blue-800 mb-2">配置说明:</h4>
        <ul className="text-xs text-blue-700 space-y-1">
          <li>• 开发环境: 确保后端服务在 localhost:3001 运行</li>
          <li>• 生产环境: 在 Vercel 中配置 NEXT_PUBLIC_API_URL 环境变量</li>
          <li>• Railway 后端: 配置 FRONTEND_URL 和 CORS_ORIGIN 环境变量</li>
        </ul>
      </div>
    </div>
  );
}