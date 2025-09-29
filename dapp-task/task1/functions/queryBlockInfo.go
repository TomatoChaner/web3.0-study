package functions

import (
	"context"
	"fmt"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

// 查询区块信息
func QueryBlockInfo(client *ethclient.Client, blockNumber uint64) error {
	// 输入验证
	if client == nil {
		return fmt.Errorf("客户端不能为空")
	}
	
	// 获取最新区块号进行验证
	latestBlock, err := client.BlockByNumber(context.Background(), nil)
	if err != nil {
		return fmt.Errorf("获取最新区块失败: %v", err)
	}
	
	if blockNumber > latestBlock.Number().Uint64() {
		return fmt.Errorf("区块号 %d 超出范围，最新区块号为 %d", blockNumber, latestBlock.Number().Uint64())
	}
	
	block, err := client.BlockByNumber(context.Background(), big.NewInt(int64(blockNumber)))
	if err != nil {
		return fmt.Errorf("获取区块 %d 失败: %v", blockNumber, err)
	}
	
	fmt.Println("=== 区块基本信息 ===")
	fmt.Printf("区块号: %d\n", block.Number().Uint64())
	fmt.Printf("区块哈希: %s\n", block.Hash().Hex())
	fmt.Printf("父区块哈希: %s\n", block.ParentHash().Hex())
	fmt.Printf("区块时间: %s\n", time.Unix(int64(block.Time()), 0).Format("2006-01-02 15:04:05"))
	fmt.Printf("时间戳: %d\n", block.Time())
	
	fmt.Println("\n=== 区块详细信息 ===")
	fmt.Printf("矿工地址: %s\n", block.Coinbase().Hex())
	fmt.Printf("难度: %s\n", block.Difficulty().String())
	fmt.Printf("Gas限制: %d\n", block.GasLimit())
	fmt.Printf("Gas使用量: %d\n", block.GasUsed())
	fmt.Printf("Gas使用率: %.2f%%\n", float64(block.GasUsed())/float64(block.GasLimit())*100)
	fmt.Printf("Nonce: %d\n", block.Nonce())
	fmt.Printf("Extra数据: %x\n", block.Extra())
	
	fmt.Println("\n=== 区块结构信息 ===")
	fmt.Printf("状态根: %s\n", block.Root().Hex())
	fmt.Printf("交易根: %s\n", block.TxHash().Hex())
	fmt.Printf("收据根: %s\n", block.ReceiptHash().Hex())
	bloom := block.Bloom()
	fmt.Printf("Bloom过滤器: %x...\n", bloom[:32])
	fmt.Printf("区块大小: %d bytes\n", block.Size())
	
	fmt.Println("\n=== 交易信息 ===")
	transactions := block.Transactions()
	fmt.Printf("交易数量: %d\n", transactions.Len())
	
	if transactions.Len() > 0 {
		fmt.Println("\n前5笔交易详情:")
		for i, tx := range transactions {
			if i >= 5 {
				break
			}
			fmt.Printf("  交易 %d:\n", i+1)
			fmt.Printf("    哈希: %s\n", tx.Hash().Hex())
			fmt.Printf("    发送方: %s\n", getSender(tx))
			if tx.To() != nil {
				fmt.Printf("    接收方: %s\n", tx.To().Hex())
			} else {
				fmt.Printf("    接收方: 合约创建\n")
			}
			fmt.Printf("    金额: %s ETH\n", weiToEther(tx.Value()))
			fmt.Printf("    Gas价格: %s Gwei\n", weiToGwei(tx.GasPrice()))
			fmt.Printf("    Gas限制: %d\n", tx.Gas())
			fmt.Println()
		}
		
		if transactions.Len() > 5 {
			fmt.Printf("... 还有 %d 笔交易\n", transactions.Len()-5)
		}
	}
	
	return nil
}

// 获取交易发送方地址
func getSender(tx *types.Transaction) string {
	// 简化处理，返回交易哈希的前8位作为标识
	hash := tx.Hash().Hex()
	if len(hash) > 10 {
		return hash[:10] + "..."
	}
	return hash
}

// 将Wei转换为Ether
func weiToEther(wei *big.Int) string {
	ether := new(big.Float).SetInt(wei)
	ether.Quo(ether, big.NewFloat(1e18))
	return ether.Text('f', 6)
}

// 将Wei转换为Gwei
func weiToGwei(wei *big.Int) string {
	gwei := new(big.Float).SetInt(wei)
	gwei.Quo(gwei, big.NewFloat(1e9))
	return gwei.Text('f', 2)
}