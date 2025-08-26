package main

/*
题目 ：实现一个带有缓冲的通道，
生产者协程向通道中发送100个整数，
消费者协程从通道中接收这些整数并打印。
考察点 ：通道的缓冲机制。
*/

import (
	"fmt"
	"time"
)

func send(ch chan int) {
	fmt.Println("发送协程开始")
	for i := 1; i <= 100; i++ {
		fmt.Printf("发送: %d (缓冲区可用空间: %d)\n", i, cap(ch)-len(ch))
		ch <- i
		// 快速发送，无延迟
		time.Sleep(100 * time.Millisecond)
	}
	fmt.Println("发送协程结束")
	close(ch)
}
func receive(ch chan int) {
	fmt.Println("接收协程开始")
	// 延迟1秒后开始接收，让发送方先填满缓冲区
	time.Sleep(1 * time.Second)
	for i := range ch {
		fmt.Printf("接收: %d (缓冲区当前长度: %d)\n", i, len(ch))
		// 慢速接收，模拟处理时间
		time.Sleep(500 * time.Millisecond)
	}
	fmt.Println("接收协程结束")
}
func main() {
	fmt.Println("=== 缓冲通道演示 ===")
	fmt.Println("缓冲区大小: 10")
	fmt.Println("发送速度: 快 (100ms间隔)")
	fmt.Println("接收速度: 慢 (500ms间隔)")
	fmt.Println()
	
	ch := make(chan int, 10)
	go send(ch)
	go receive(ch)
	
	// 等待足够时间让所有操作完成
	time.Sleep(60 * time.Second)
	fmt.Println("\n程序结束")
}
