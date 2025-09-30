package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"solana-go-assignment/internal/config"
	"solana-go-assignment/pkg/chain"
	"solana-go-assignment/pkg/contract"
)

/*
代币交换示例

要运行此示例，请使用以下命令之一：
1. 单独运行: go run examples/token_swap_example.go
2. 或者将此文件复制到单独的目录中运行

此示例演示了如何使用 Solana Go SDK 进行代币交换操作。
*/

// TokenSwapExample 演示代币交换功能
func TokenSwapExample() {
	fmt.Println("=== Solana 代币交换示例 ===")

	// 创建配置
	cfg, err := config.NewConfig(config.DevNet)
	if err != nil {
		log.Fatalf("创建配置失败: %v", err)
	}

	// 创建区块链客户端
	chainClient, err := chain.NewClient(cfg.RPCEndpoint, cfg.WSEndpoint, cfg.Network)
	if err != nil {
		log.Fatalf("创建区块链客户端失败: %v", err)
	}
	defer chainClient.Close()

	// 创建代币交换客户端
	swapClient := contract.NewTokenSwapClient(chainClient, cfg.Network)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// 示例代币地址（这些是 Solana DevNet 上的示例代币）
	tokenA := "So11111111111111111111111111111111111111112" // Wrapped SOL
	tokenB := "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" // USDC (示例)
	poolAddress := "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM" // 示例池地址

	// 1. 获取代币信息
	fmt.Println("\n1. 获取代币信息...")
	tokenInfoA, err := swapClient.GetTokenInfo(ctx, tokenA)
	if err != nil {
		log.Printf("获取代币A信息失败: %v", err)
	} else {
		fmt.Printf("✓ 代币A: %s\n", tokenInfoA.Symbol)
		fmt.Printf("  地址: %s\n", tokenInfoA.Mint.String())
		fmt.Printf("  小数位: %d\n", tokenInfoA.Decimals)
		fmt.Printf("  总供应量: %d\n", tokenInfoA.Supply)
	}

	tokenInfoB, err := swapClient.GetTokenInfo(ctx, tokenB)
	if err != nil {
		log.Printf("获取代币B信息失败: %v", err)
	} else {
		fmt.Printf("✓ 代币B: %s\n", tokenInfoB.Symbol)
		fmt.Printf("  地址: %s\n", tokenInfoB.Mint.String())
		fmt.Printf("  小数位: %d\n", tokenInfoB.Decimals)
		fmt.Printf("  总供应量: %d\n", tokenInfoB.Supply)
	}

	// 2. 获取交换池信息
	fmt.Println("\n2. 获取交换池信息...")
	poolInfo, err := swapClient.GetPoolInfo(ctx, poolAddress)
	if err != nil {
		log.Printf("获取池信息失败: %v", err)
	} else {
		fmt.Printf("✓ 池地址: %s\n", poolInfo.Address.String())
		fmt.Printf("✓ 代币A储备: %d\n", poolInfo.ReserveA)
		fmt.Printf("✓ 代币B储备: %d\n", poolInfo.ReserveB)
		fmt.Printf("✓ 流动性代币供应: %d\n", poolInfo.LPTokenSupply)
		feeRate := float64(poolInfo.FeeNumerator) / float64(poolInfo.FeeDenominator)
		fmt.Printf("✓ 交易费率: %.4f%%\n", feeRate*100)
	}

	// 3. 计算交换报价
	fmt.Println("\n3. 计算交换报价...")
	inputAmount := uint64(1000000) // 1 SOL (假设 6 位小数)
	slippageTolerance := 1.0       // 1% 滑点容忍度

	swapQuote, err := swapClient.GetSwapQuote(ctx, poolAddress, tokenA, tokenB, inputAmount, slippageTolerance)
	if err != nil {
		log.Printf("获取交换报价失败: %v", err)
	} else {
		fmt.Printf("✓ 输入数量: %d\n", swapQuote.InputAmount)
		fmt.Printf("✓ 预期输出: %d\n", swapQuote.OutputAmount)
		fmt.Printf("✓ 最小输出: %d\n", swapQuote.MinOutput)
		fmt.Printf("✓ 价格影响: %.4f%%\n", swapQuote.PriceImpact*100)
		fmt.Printf("✓ 交易费用: %d\n", swapQuote.Fee)
		fmt.Printf("✓ 汇率: %.6f\n", swapQuote.ExchangeRate)
		fmt.Printf("✓ 滑点容忍度: %.2f%%\n", swapQuote.SlippageTolerance)
	}

	// 4. 计算流动性报价
	fmt.Println("\n4. 计算流动性报价...")
	tokenAAmount := uint64(500000) // 0.5 SOL
	tokenBAmount := uint64(500000) // 相应的代币B数量

	liquidityQuote, err := swapClient.GetLiquidityQuote(ctx, poolAddress, tokenAAmount, tokenBAmount)
	if err != nil {
		log.Printf("获取流动性报价失败: %v", err)
	} else {
		fmt.Printf("✓ 代币A数量: %d\n", liquidityQuote.TokenAAmount)
		fmt.Printf("✓ 代币B数量: %d\n", liquidityQuote.TokenBAmount)
		fmt.Printf("✓ LP代币数量: %d\n", liquidityQuote.LPTokenAmount)
		fmt.Printf("✓ 池份额: %.6f%%\n", liquidityQuote.ShareOfPool)
	}

	// 5. 模拟不同数量的交换
	fmt.Println("\n5. 模拟不同数量的交换...")
	amounts := []uint64{100000, 500000, 1000000, 5000000} // 不同的输入数量
	
	for _, amount := range amounts {
		quote, err := swapClient.GetSwapQuote(ctx, poolAddress, tokenA, tokenB, amount, slippageTolerance)
		if err != nil {
			log.Printf("模拟交换失败 (数量: %d): %v", amount, err)
			continue
		}
		
		inputSOL := float64(amount) / 1e6  // 假设 6 位小数
		outputTokens := float64(quote.OutputAmount) / 1e6
		
		fmt.Printf("  输入: %.6f SOL -> 输出: %.6f 代币 (汇率: %.6f)\n", 
			inputSOL, outputTokens, quote.ExchangeRate)
	}

	// 6. 模拟交换操作
	fmt.Println("\n6. 模拟交换操作...")
	simulationResult, err := swapClient.SimulateSwap(ctx, poolAddress, tokenA, tokenB, inputAmount, slippageTolerance)
	if err != nil {
		log.Printf("模拟交换失败: %v", err)
	} else {
		fmt.Printf("✓ 模拟签名: %s\n", simulationResult.Signature)
		fmt.Printf("✓ 输入数量: %d\n", simulationResult.InputAmount)
		fmt.Printf("✓ 输出数量: %d\n", simulationResult.OutputAmount)
		fmt.Printf("✓ 交易费用: %d\n", simulationResult.Fee)
		fmt.Printf("✓ 价格影响: %.4f%%\n", simulationResult.PriceImpact*100)
		fmt.Printf("✓ 状态: %s\n", simulationResult.Status)
	}

	// 7. 获取池统计信息
	fmt.Println("\n7. 获取池统计信息...")
	stats, err := swapClient.GetPoolStats(ctx, poolAddress)
	if err != nil {
		log.Printf("获取统计信息失败: %v", err)
	} else {
		fmt.Printf("✓ 池统计信息:\n")
		for key, value := range stats {
			fmt.Printf("  %s: %v\n", key, value)
		}
	}

	fmt.Println("\n=== 代币交换示例完成 ===")
	fmt.Println("\n注意: 这是一个模拟示例，实际交换需要:")
	fmt.Println("- 有效的钱包私钥")
	fmt.Println("- 足够的代币余额")
	fmt.Println("- 正确的池地址和代币地址")
	fmt.Println("- 网络费用 (SOL)")
}

// 如果要单独运行此文件，请取消注释下面的 main 函数
// func main() {
//     TokenSwapExample()
// }