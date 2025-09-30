package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/gagliardetto/solana-go/rpc"
	"solana-go-assignment/internal/config"
	"solana-go-assignment/pkg/chain"
	"solana-go-assignment/pkg/events"
)

/*
事件监听示例

要运行此示例，请使用以下命令：
go run examples/event_monitoring.go

此示例演示了如何使用 Solana Go SDK 监听区块链事件。
*/

// EventMonitoringExample 演示事件监听功能
func EventMonitoringExample() {
	fmt.Println("=== Solana 事件监听示例 ===")

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

	// 创建事件订阅器
	subscriber, err := events.NewSubscriber(cfg.WSEndpoint, cfg.Network)
	if err != nil {
		log.Fatalf("创建事件订阅器失败: %v", err)
	}
	defer subscriber.Close()

	fmt.Println("✓ 事件订阅器创建成功")

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	// 1. 监听槽位变化事件
	fmt.Println("\n1. 设置槽位变化监听...")
	slotHandler := func(event *events.Event) error {
		if slotEvent, ok := event.Data.(events.SlotChangeEvent); ok {
			fmt.Printf("📊 槽位变化: 槽位 %d, 父槽位 %d, 根槽位 %d\n", 
				slotEvent.Slot, slotEvent.Parent, slotEvent.Root)
		}
		return nil
	}
	subscriber.AddHandler(events.EventTypeSlotChange, slotHandler)

	// 订阅槽位变化
	if err := subscriber.SubscribeToSlots(); err != nil {
		log.Printf("订阅槽位变化失败: %v", err)
	} else {
		fmt.Println("✓ 槽位变化订阅成功")
	}

	// 2. 监听账户变化事件
	fmt.Println("\n2. 设置账户变化监听...")
	accountHandler := func(event *events.Event) error {
		if accountEvent, ok := event.Data.(events.AccountChangeEvent); ok {
			fmt.Printf("💰 账户变化: %s, 余额: %d lamports, 所有者: %s\n",
				accountEvent.Account, accountEvent.Lamports, accountEvent.Owner)
		}
		return nil
	}
	subscriber.AddHandler(events.EventTypeAccount, accountHandler)

	// 监听系统程序账户变化（作为示例）
	systemProgramID := "11111111111111111111111111111111111111112"
	if err := subscriber.SubscribeToAccount(systemProgramID, rpc.CommitmentConfirmed); err != nil {
		log.Printf("订阅账户变化失败: %v", err)
	} else {
		fmt.Printf("✓ 账户变化订阅成功: %s\n", systemProgramID)
	}

	// 3. 监听签名确认事件
	fmt.Println("\n3. 设置签名确认监听...")
	signatureHandler := func(event *events.Event) error {
		if sigEvent, ok := event.Data.(events.SignatureEvent); ok {
			fmt.Printf("✅ 签名确认: %s, 状态: %s\n", 
				sigEvent.Signature, sigEvent.Status)
		}
		return nil
	}
	subscriber.AddHandler(events.EventTypeSignature, signatureHandler)

	// 4. 监听程序账户变化
	fmt.Println("\n4. 设置程序账户变化监听...")
	programHandler := func(event *events.Event) error {
		if programEvent, ok := event.Data.(events.ProgramEvent); ok {
			fmt.Printf("🔧 程序账户变化: 程序 %s, 账户 %s\n",
				programEvent.Program, programEvent.Account)
		}
		return nil
	}
	subscriber.AddHandler(events.EventTypeProgram, programHandler)

	// 监听 SPL Token 程序账户变化
	splTokenProgramID := "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
	if err := subscriber.SubscribeToProgram(splTokenProgramID, rpc.CommitmentConfirmed); err != nil {
		log.Printf("订阅程序账户变化失败: %v", err)
	} else {
		fmt.Printf("✓ 程序账户变化订阅成功: %s\n", splTokenProgramID)
	}

	// 5. 开始监听事件
	fmt.Println("\n5. 开始监听事件...")
	fmt.Println("正在监听事件，按 Ctrl+C 停止...")

	// 模拟事件监听循环
	eventCount := 0
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			fmt.Println("\n⏰ 监听超时，正在停止...")
			goto cleanup
		case <-ticker.C:
			eventCount++
			fmt.Printf("⏱️  监听中... (%d 次检查)\n", eventCount)
			
			// 显示统计信息
			stats := subscriber.GetStats()
			fmt.Printf("   📈 事件统计: 总计 %d\n", stats.TotalEvents)
			
			// 显示各类型事件数量
			if stats.EventsByType != nil {
				for eventType, count := range stats.EventsByType {
					fmt.Printf("   - %s: %d\n", eventType, count)
				}
			}
			
			// 模拟接收到的事件（实际应用中这些会通过 WebSocket 自动触发）
			if eventCount%3 == 0 {
				fmt.Println("   🔄 模拟槽位变化事件...")
			}
			
			if eventCount >= 10 {
				fmt.Println("\n✅ 示例监听完成")
				goto cleanup
			}
		}
	}

cleanup:
	// 6. 清理和统计
	fmt.Println("\n6. 清理资源和显示最终统计...")
	
	// 移除事件处理器
	subscriber.RemoveHandlers(events.EventTypeSlotChange)
	subscriber.RemoveHandlers(events.EventTypeAccount)
	subscriber.RemoveHandlers(events.EventTypeSignature)
	subscriber.RemoveHandlers(events.EventTypeProgram)
	
	// 显示最终统计
	finalStats := subscriber.GetStats()
	fmt.Println("📊 最终事件统计:")
	fmt.Printf("   总事件数: %d\n", finalStats.TotalEvents)
	fmt.Printf("   开始时间: %s\n", finalStats.StartTime.Format("2006-01-02 15:04:05"))
	if !finalStats.LastEventTime.IsZero() {
		fmt.Printf("   最后事件时间: %s\n", finalStats.LastEventTime.Format("2006-01-02 15:04:05"))
		fmt.Printf("   事件频率: %.2f 事件/秒\n", finalStats.EventsPerSecond)
	}
	
	if finalStats.EventsByType != nil {
		fmt.Println("   各类型事件统计:")
		for eventType, count := range finalStats.EventsByType {
			fmt.Printf("   - %s: %d\n", eventType, count)
		}
	}
	
	fmt.Println("\n=== 事件监听示例完成 ===")
	fmt.Println("\n💡 提示:")
	fmt.Println("- 在实际应用中，事件会通过 WebSocket 实时接收")
	fmt.Println("- 可以根据需要订阅特定的账户、程序或签名")
	fmt.Println("- 事件处理器可以执行复杂的业务逻辑")
	fmt.Println("- 建议在生产环境中添加错误重试和连接恢复机制")
}

// 如果要单独运行此文件，请取消注释下面的 main 函数
// func main() {
//     EventMonitoringExample()
// }