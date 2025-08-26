package main

/*
题目 ：编写一个程序，使用 go 关键字启动两个协程，
一个协程打印从1到10的奇数，
另一个协程打印从2到10的偶数。
考察点 ： go 关键字的使用、协程的并发执行。
*/
import (
	"fmt"
	"sync"
)

// printOdd 打印从1到10的奇数
func printOdd() {
	for i := 1; i <= 10; i += 2 {
		fmt.Println(i)
	}
}

// printEven 打印从2到10的偶数
func printEven() {
	for i := 2; i <= 10; i += 2 {
		fmt.Println(i)
	}
}

func main() {
	fmt.Println("=== 测试 goroutine 函数 ===")
	
	// 使用 WaitGroup 来等待协程完成
	var wg sync.WaitGroup
	wg.Add(2) // 添加两个协程到等待组
	
	// 启动打印奇数的协程
	go func() {
		defer wg.Done() // 协程完成时调用 Done()
		fmt.Println("奇数:")
		printOdd()
	}()
	
	// 启动打印偶数的协程
	go func() {
		defer wg.Done() // 协程完成时调用 Done()
		fmt.Println("偶数:")
		printEven()
	}()
	
	// 等待所有协程完成
	wg.Wait()
	fmt.Println("所有协程执行完成")
}
