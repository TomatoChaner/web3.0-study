package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"solana-go-assignment/internal/config"
	"solana-go-assignment/pkg/chain"
)

// runBasicChainQuery 演示基本的区块链查询功能
// 要运行此示例，请使用: go run examples/basic_chain_query.go
func runBasicChainQuery() {
	fmt.Println("=== Solana 区块链基础查询示例 ===")

	// 创建配置
	cfg, err := config.NewConfig(config.DevNet)
	if err != nil {
		log.Fatalf("创建配置失败: %v", err)
	}

	// 创建客户端
	client, err := chain.NewClient(cfg.RPCEndpoint, cfg.WSEndpoint, cfg.Network)
	if err != nil {
		log.Fatalf("创建客户端失败: %v", err)
	}
	defer client.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// 1. 检查网络健康状态
	fmt.Println("\n1. 检查网络健康状态...")
	if err := client.GetHealth(ctx); err != nil {
		log.Printf("网络健康检查失败: %v", err)
	} else {
		fmt.Println("✓ 网络状态正常")
	}

	// 2. 获取当前区块高度
	fmt.Println("\n2. 获取当前区块高度...")
	blockHeight, err := client.GetBlockHeight(ctx)
	if err != nil {
		log.Printf("获取区块高度失败: %v", err)
	} else {
		fmt.Printf("✓ 当前区块高度: %d\n", blockHeight)
	}

	// 3. 获取当前槽位
	fmt.Println("\n3. 获取当前槽位...")
	slot, err := client.GetSlot(ctx)
	if err != nil {
		log.Printf("获取槽位失败: %v", err)
	} else {
		fmt.Printf("✓ 当前槽位: %d\n", slot)
	}

	// 4. 获取最新区块哈希
	fmt.Println("\n4. 获取最新区块哈希...")
	blockInfo, err := client.GetLatestBlockhash(ctx)
	if err != nil {
		log.Printf("获取区块哈希失败: %v", err)
	} else {
		fmt.Printf("✓ 最新区块哈希: %s\n", blockInfo.Blockhash)
		fmt.Printf("✓ 区块槽位: %d\n", blockInfo.Slot)
	}

	// 5. 查询特定账户余额（使用一个已知的系统账户）
	fmt.Println("\n5. 查询账户余额...")
	systemProgramAddress := "11111111111111111111111111111112" // System Program
	accountInfo, err := client.GetAccountBalance(ctx, systemProgramAddress)
	if err != nil {
		log.Printf("查询账户余额失败: %v", err)
	} else {
		fmt.Printf("✓ 账户地址: %s\n", systemProgramAddress)
		fmt.Printf("✓ 账户余额: %.9f SOL\n", float64(accountInfo.Balance)/1e9)
	}

	// 6. 获取账户详细信息
	fmt.Println("\n6. 获取账户详细信息...")
	detailedInfo, err := client.GetAccountInfo(ctx, systemProgramAddress)
	if err != nil {
		log.Printf("获取账户信息失败: %v", err)
	} else {
		fmt.Printf("✓ 账户地址: %s\n", detailedInfo.Address)
		fmt.Printf("✓ 余额: %.9f SOL\n", float64(detailedInfo.Balance)/1e9)
		fmt.Printf("✓ 所有者: %s\n", detailedInfo.Owner)
		fmt.Printf("✓ 可执行: %t\n", detailedInfo.Executable)
		fmt.Printf("✓ 数据大小: %d bytes\n", detailedInfo.DataSize)
	}

	// 7. 获取最近的区块信息
	fmt.Println("\n7. 获取最近的区块信息...")
	if slot > 0 {
		recentBlockInfo, err := client.GetBlock(ctx, slot-1) // 获取前一个区块
		if err != nil {
			log.Printf("获取区块信息失败: %v", err)
		} else {
			fmt.Printf("✓ 区块槽位: %d\n", recentBlockInfo.Slot)
			fmt.Printf("✓ 区块哈希: %s\n", recentBlockInfo.Blockhash)
			fmt.Printf("✓ 父槽位: %d\n", recentBlockInfo.ParentSlot)
			fmt.Printf("✓ 交易数量: %d\n", recentBlockInfo.Transactions)
			if recentBlockInfo.BlockTime != nil {
				fmt.Printf("✓ 区块时间: %s\n", time.Unix(*recentBlockInfo.BlockTime, 0).Format("2006-01-02 15:04:05"))
			}
		}
	}

	fmt.Println("\n=== 区块链查询示例完成 ===")
}

func main() {
	runBasicChainQuery()
}