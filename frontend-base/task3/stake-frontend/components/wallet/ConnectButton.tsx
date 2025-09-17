'use client';

import { ConnectButton as RainbowConnectButton } from '@rainbow-me/rainbowkit';
import { Wallet, ChevronDown, Copy, ExternalLink, LogOut } from 'lucide-react';
import { useState } from 'react';
import { formatAddress } from '../../utils/format';
import { useAccount, useBalance, useDisconnect } from 'wagmi';
import { toast } from 'react-hot-toast';

interface ConnectButtonProps {
  className?: string;
  variant?: 'primary' | 'secondary' | 'outline';
  size?: 'sm' | 'md' | 'lg';
}

export default function ConnectButton({ 
  className = '', 
  variant = 'primary',
  size = 'md' 
}: ConnectButtonProps) {
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const { address, isConnected } = useAccount();
  const { data: balance } = useBalance({ address });
  const { disconnect } = useDisconnect();

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg'
  };

  const variantClasses = {
    primary: 'bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white',
    secondary: 'bg-gray-600 hover:bg-gray-700 text-white',
    outline: 'border-2 border-blue-600 text-blue-600 hover:bg-blue-600 hover:text-white'
  };

  const copyAddress = async () => {
    if (address) {
      await navigator.clipboard.writeText(address);
      toast.success('地址已复制到剪贴板');
    }
  };

  const openEtherscan = () => {
    if (address) {
      window.open(`https://etherscan.io/address/${address}`, '_blank');
    }
  };

  const handleDisconnect = () => {
    disconnect();
    setIsDropdownOpen(false);
    toast.success('钱包已断开连接');
  };

  return (
    <RainbowConnectButton.Custom>
      {({
        account,
        chain,
        openAccountModal,
        openChainModal,
        openConnectModal,
        authenticationStatus,
        mounted,
      }) => {
        // 确保组件已挂载
        const ready = mounted && authenticationStatus !== 'loading';
        const connected =
          ready &&
          account &&
          chain &&
          (!authenticationStatus ||
            authenticationStatus === 'authenticated');

        return (
          <div className={`relative ${className}`}>
            {(() => {
              if (!connected) {
                return (
                  <button
                    onClick={openConnectModal}
                    type="button"
                    className={`
                      inline-flex items-center gap-2 rounded-lg font-medium
                      transition-all duration-200 transform hover:scale-105
                      shadow-lg hover:shadow-xl
                      ${sizeClasses[size]}
                      ${variantClasses[variant]}
                    `}
                  >
                    <Wallet className="w-5 h-5" />
                    连接钱包
                  </button>
                );
              }

              if (chain.unsupported) {
                return (
                  <button
                    onClick={openChainModal}
                    type="button"
                    className={`
                      inline-flex items-center gap-2 rounded-lg font-medium
                      bg-red-600 hover:bg-red-700 text-white
                      transition-all duration-200
                      ${sizeClasses[size]}
                    `}
                  >
                    ⚠️ 错误网络
                  </button>
                );
              }

              return (
                <div className="relative">
                  <button
                    onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                    type="button"
                    className={`
                      inline-flex items-center gap-2 rounded-lg font-medium
                      transition-all duration-200 transform hover:scale-105
                      shadow-lg hover:shadow-xl
                      ${sizeClasses[size]}
                      ${variantClasses[variant]}
                    `}
                  >
                    <div className="flex items-center gap-2">
                      {chain.hasIcon && (
                        <div
                          style={{
                            background: chain.iconBackground,
                            width: 20,
                            height: 20,
                            borderRadius: 999,
                            overflow: 'hidden',
                            marginRight: 4,
                          }}
                        >
                          {chain.iconUrl && (
                            <img
                              alt={chain.name ?? 'Chain icon'}
                              src={chain.iconUrl}
                              style={{ width: 20, height: 20 }}
                            />
                          )}
                        </div>
                      )}
                      <span>{formatAddress(account.address)}</span>
                      <ChevronDown className={`w-4 h-4 transition-transform ${isDropdownOpen ? 'rotate-180' : ''}`} />
                    </div>
                  </button>

                  {/* 下拉菜单 */}
                  {isDropdownOpen && (
                    <>
                      {/* 背景遮罩 */}
                      <div
                        className="fixed inset-0 z-10"
                        onClick={() => setIsDropdownOpen(false)}
                      />
                      
                      {/* 下拉内容 */}
                      <div className="absolute right-0 mt-2 w-80 bg-white dark:bg-gray-800 rounded-lg shadow-xl border border-gray-200 dark:border-gray-700 z-20">
                        <div className="p-4">
                          {/* 账户信息 */}
                          <div className="flex items-center gap-3 mb-4">
                            <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full flex items-center justify-center">
                              <Wallet className="w-5 h-5 text-white" />
                            </div>
                            <div>
                              <div className="font-medium text-gray-900 dark:text-white">
                                {account.displayName}
                              </div>
                              <div className="text-sm text-gray-500 dark:text-gray-400">
                                {formatAddress(account.address)}
                              </div>
                            </div>
                          </div>

                          {/* 余额信息 */}
                          {balance && (
                            <div className="mb-4 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                              <div className="text-sm text-gray-500 dark:text-gray-400 mb-1">
                                余额
                              </div>
                              <div className="font-medium text-gray-900 dark:text-white">
                                {parseFloat(balance.formatted).toFixed(4)} {balance.symbol}
                              </div>
                            </div>
                          )}

                          {/* 网络信息 */}
                          <div className="mb-4 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                            <div className="text-sm text-gray-500 dark:text-gray-400 mb-1">
                              网络
                            </div>
                            <div className="flex items-center gap-2">
                              {chain.hasIcon && (
                                <div
                                  style={{
                                    background: chain.iconBackground,
                                    width: 16,
                                    height: 16,
                                    borderRadius: 999,
                                    overflow: 'hidden',
                                  }}
                                >
                                  {chain.iconUrl && (
                                    <img
                                      alt={chain.name ?? 'Chain icon'}
                                      src={chain.iconUrl}
                                      style={{ width: 16, height: 16 }}
                                    />
                                  )}
                                </div>
                              )}
                              <span className="font-medium text-gray-900 dark:text-white">
                                {chain.name}
                              </span>
                            </div>
                          </div>

                          {/* 操作按钮 */}
                          <div className="space-y-2">
                            <button
                              onClick={copyAddress}
                              className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-600 rounded-lg transition-colors"
                            >
                              <Copy className="w-4 h-4" />
                              复制地址
                            </button>
                            
                            <button
                              onClick={openEtherscan}
                              className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-600 rounded-lg transition-colors"
                            >
                              <ExternalLink className="w-4 h-4" />
                              在 Etherscan 查看
                            </button>
                            
                            <button
                              onClick={openChainModal}
                              className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-600 rounded-lg transition-colors"
                            >
                              <ExternalLink className="w-4 h-4" />
                              切换网络
                            </button>
                            
                            <hr className="border-gray-200 dark:border-gray-600" />
                            
                            <button
                              onClick={handleDisconnect}
                              className="w-full flex items-center gap-2 px-3 py-2 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                            >
                              <LogOut className="w-4 h-4" />
                              断开连接
                            </button>
                          </div>
                        </div>
                      </div>
                    </>
                  )}
                </div>
              );
            })()}
          </div>
        );
      }}
    </RainbowConnectButton.Custom>
  );
}