package main

/*
题目 ：编写一个程序，使用 sync.Mutex 来保护一个共享的计数器。
启动10个协程，每个协程对计数器进行1000次递增操作，最后输出计数器的值。
考察点 ： sync.Mutex 的使用、并发数据安全。
*/
import (
	"fmt"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"
)

// 全局变量
var (
	counter int            // 共享计数器
	mutex   sync.Mutex     // 互斥锁
	wg      sync.WaitGroup // 等待组
)

// 获取当前协程ID
func getGoroutineID() int {
	buf := make([]byte, 64)
	buf = buf[:runtime.Stack(buf, false)]
	idField := strings.Fields(strings.TrimPrefix(string(buf), "goroutine "))[0]
	id, _ := strconv.Atoi(idField)
	return id
}

// 递增函数
func increment() {
	defer wg.Done() // 协程结束时调用Done
	goroutineID := getGoroutineID()

	for i := 0; i < 1000; i++ {
		mutex.Lock() // 加锁
		counter++    // 递增计数器
		// 每100次打印一次进度，显示真实协程ID
		if counter%100 == 0 {
			fmt.Printf("协程 %d 计数 %d\n", goroutineID, counter)
		}
		mutex.Unlock() // 解锁
	}
	fmt.Printf("协程 %d 完成所有递增操作\n", goroutineID)
}

func main() {
	fmt.Println("=== 互斥锁并发安全演示 ===")
	fmt.Println("启动10个协程，每个协程递增1000次")
	fmt.Println("预期结果：10000")
	fmt.Println()

	startTime := time.Now()

	// 启动10个协程
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go increment()
		fmt.Printf("启动协程 %d\n", i+1)
	}

	fmt.Println("\n等待所有协程完成...")
	wg.Wait() // 等待所有协程完成

	elapsedTime := time.Since(startTime)

	fmt.Printf("\n=== 结果 ===\n")
	fmt.Printf("最终计数器值: %d\n", counter)
	fmt.Printf("执行时间: %v\n", elapsedTime)

	if counter == 10000 {
		fmt.Println("结果正确！互斥锁成功保护了共享数据")
	} else {
		fmt.Println("结果错误！可能存在竞态条件")
	}
}
