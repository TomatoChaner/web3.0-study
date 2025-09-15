// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ProxyAdmin
 * @dev 代理管理合约，用于管理UUPS代理的升级
 * @notice 这个合约负责管理所有代理合约的升级操作
 */
contract ProxyAdmin is Ownable {
    using Address for address;

    // ============ 事件 ============
    
    event ProxyUpgraded(
        address indexed proxy,
        address indexed oldImplementation,
        address indexed newImplementation
    );
    
    event ProxyDeployed(
        address indexed proxy,
        address indexed implementation,
        bytes data
    );

    // ============ 状态变量 ============
    
    /// @dev 管理的代理合约列表
    address[] public managedProxies;
    
    /// @dev 代理合约映射
    mapping(address => bool) public isManaged;
    
    /// @dev 代理合约的实现历史
    mapping(address => address[]) public implementationHistory;

    // ============ 构造函数 ============
    
    constructor(address initialOwner) Ownable(initialOwner) {}

    // ============ 代理部署 ============
    
    /**
     * @dev 部署新的UUPS代理
     * @param implementation 实现合约地址
     * @param data 初始化数据
     * @return proxy 代理合约地址
     */
    function deployProxy(
        address implementation,
        bytes memory data
    ) external onlyOwner returns (address proxy) {
        require(implementation != address(0), "ProxyAdmin: invalid implementation");
        require(implementation.code.length > 0, "ProxyAdmin: implementation not a contract");
        
        // 部署ERC1967代理
        proxy = address(new ERC1967Proxy(implementation, data));
        
        // 添加到管理列表
        managedProxies.push(proxy);
        isManaged[proxy] = true;
        implementationHistory[proxy].push(implementation);
        
        emit ProxyDeployed(proxy, implementation, data);
        
        return proxy;
    }

    // ============ 代理升级 ============
    
    /**
     * @dev 升级代理实现
     * @param proxy 代理合约地址
     * @param newImplementation 新实现合约地址
     */
    function upgrade(
        address proxy,
        address newImplementation
    ) external onlyOwner {
        require(isManaged[proxy], "ProxyAdmin: proxy not managed");
        require(newImplementation != address(0), "ProxyAdmin: invalid implementation");
        require(newImplementation.code.length > 0, "ProxyAdmin: implementation not a contract");
        
        address oldImplementation = getImplementation(proxy);
        require(oldImplementation != newImplementation, "ProxyAdmin: same implementation");
        
        // 执行升级
        (bool success, ) = proxy.call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                newImplementation,
                ""
            )
        );
        require(success, "ProxyAdmin: upgrade failed");
        
        // 记录实现历史
        implementationHistory[proxy].push(newImplementation);
        
        emit ProxyUpgraded(proxy, oldImplementation, newImplementation);
    }
    
    /**
     * @dev 升级代理实现并调用函数
     * @param proxy 代理合约地址
     * @param newImplementation 新实现合约地址
     * @param data 调用数据
     */
    function upgradeAndCall(
        address proxy,
        address newImplementation,
        bytes memory data
    ) external onlyOwner {
        require(isManaged[proxy], "ProxyAdmin: proxy not managed");
        require(newImplementation != address(0), "ProxyAdmin: invalid implementation");
        require(newImplementation.code.length > 0, "ProxyAdmin: implementation not a contract");
        
        address oldImplementation = getImplementation(proxy);
        require(oldImplementation != newImplementation, "ProxyAdmin: same implementation");
        
        // 执行升级并调用
        (bool success, ) = proxy.call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                newImplementation,
                data
            )
        );
        require(success, "ProxyAdmin: upgrade failed");
        
        // 记录实现历史
        implementationHistory[proxy].push(newImplementation);
        
        emit ProxyUpgraded(proxy, oldImplementation, newImplementation);
    }

    // ============ 查询函数 ============
    
    /**
     * @dev 获取代理的当前实现地址
     * @param proxy 代理合约地址
     * @return implementation 实现合约地址
     */
    function getImplementation(address proxy) public view returns (address implementation) {
        // ERC1967 实现槽
        bytes32 slot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        
        assembly {
            implementation := sload(slot)
        }
        
        return implementation;
    }
    
    /**
     * @dev 获取代理的管理员地址
     * @param proxy 代理合约地址
     * @return admin 管理员地址
     */
    function getAdmin(address proxy) public view returns (address admin) {
        // ERC1967 管理员槽
        bytes32 slot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        
        assembly {
            admin := sload(slot)
        }
        
        return admin;
    }
    
    /**
     * @dev 获取管理的代理数量
     * @return count 代理数量
     */
    function getManagedProxyCount() external view returns (uint256) {
        return managedProxies.length;
    }
    
    /**
     * @dev 获取所有管理的代理地址
     * @return proxies 代理地址数组
     */
    function getAllManagedProxies() external view returns (address[] memory) {
        return managedProxies;
    }
    
    /**
     * @dev 获取代理的实现历史
     * @param proxy 代理合约地址
     * @return implementations 实现地址数组
     */
    function getImplementationHistory(address proxy) 
        external 
        view 
        returns (address[] memory) 
    {
        return implementationHistory[proxy];
    }
    
    /**
     * @dev 检查代理是否由此合约管理
     * @param proxy 代理合约地址
     * @return managed 是否管理
     */
    function isManagedProxy(address proxy) external view returns (bool) {
        return isManaged[proxy];
    }

    // ============ 管理函数 ============
    
    /**
     * @dev 添加现有代理到管理列表
     * @param proxy 代理合约地址
     */
    function addManagedProxy(address proxy) external onlyOwner {
        require(proxy != address(0), "ProxyAdmin: invalid proxy");
        require(proxy.code.length > 0, "ProxyAdmin: proxy not a contract");
        require(!isManaged[proxy], "ProxyAdmin: already managed");
        
        managedProxies.push(proxy);
        isManaged[proxy] = true;
        
        // 记录当前实现
        address currentImplementation = getImplementation(proxy);
        if (currentImplementation != address(0)) {
            implementationHistory[proxy].push(currentImplementation);
        }
    }
    
    /**
     * @dev 从管理列表中移除代理
     * @param proxy 代理合约地址
     */
    function removeManagedProxy(address proxy) external onlyOwner {
        require(isManaged[proxy], "ProxyAdmin: proxy not managed");
        
        isManaged[proxy] = false;
        
        // 从数组中移除
        for (uint256 i = 0; i < managedProxies.length; i++) {
            if (managedProxies[i] == proxy) {
                managedProxies[i] = managedProxies[managedProxies.length - 1];
                managedProxies.pop();
                break;
            }
        }
    }

    // ============ 紧急函数 ============
    
    /**
     * @dev 紧急暂停代理（如果实现合约支持）
     * @param proxy 代理合约地址
     */
    function emergencyPause(address proxy) external onlyOwner {
        require(isManaged[proxy], "ProxyAdmin: proxy not managed");
        
        // 尝试调用pause函数
        (bool success, ) = proxy.call(abi.encodeWithSignature("pause()"));
        require(success, "ProxyAdmin: pause failed");
    }
    
    /**
     * @dev 紧急恢复代理（如果实现合约支持）
     * @param proxy 代理合约地址
     */
    function emergencyUnpause(address proxy) external onlyOwner {
        require(isManaged[proxy], "ProxyAdmin: proxy not managed");
        
        // 尝试调用unpause函数
        (bool success, ) = proxy.call(abi.encodeWithSignature("unpause()"));
        require(success, "ProxyAdmin: unpause failed");
    }

    // ============ 批量操作 ============
    
    /**
     * @dev 批量升级多个代理
     * @param proxies 代理地址数组
     * @param newImplementation 新实现地址
     */
    function batchUpgrade(
        address[] calldata proxies,
        address newImplementation
    ) external onlyOwner {
        require(newImplementation != address(0), "ProxyAdmin: invalid implementation");
        require(newImplementation.code.length > 0, "ProxyAdmin: implementation not a contract");
        
        for (uint256 i = 0; i < proxies.length; i++) {
            address proxy = proxies[i];
            require(isManaged[proxy], "ProxyAdmin: proxy not managed");
            
            address oldImplementation = getImplementation(proxy);
            if (oldImplementation != newImplementation) {
                (bool success, ) = proxy.call(
                    abi.encodeWithSignature(
                        "upgradeToAndCall(address,bytes)",
                        newImplementation,
                        ""
                    )
                );
                if (success) {
                    implementationHistory[proxy].push(newImplementation);
                    emit ProxyUpgraded(proxy, oldImplementation, newImplementation);
                }
            }
        }
    }

    // ============ 工具函数 ============
    
    /**
     * @dev 检查实现合约是否支持UUPS
     * @param implementation 实现合约地址
     * @return supported 是否支持
     */
    function supportsUUPS(address implementation) external view returns (bool) {
        if (implementation.code.length == 0) return false;
        
        try IERC165(implementation).supportsInterface(0x52d1902d) returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }
    
    /**
     * @dev 获取合约版本
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}