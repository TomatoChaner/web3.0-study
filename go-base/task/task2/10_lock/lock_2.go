package main

/*
题目 ：使用原子操作（ sync/atomic 包）实现一个无锁的计数器。
启动10个协程，每个协程对计数器进行1000次递增操作，最后输出计数器的值。
考察点 ：原子操作、并发数据安全。
*/
import (
	"fmt"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

var (
	counter int64
	wg      sync.WaitGroup
)

// 获取当前协程ID
func getGoroutineID() string {
	buf := make([]byte, 64)
	buf = buf[:runtime.Stack(buf, false)]
	idField := strings.Fields(strings.TrimPrefix(string(buf), "goroutine "))[0]
	id, _ := strconv.Atoi(idField)
	return strconv.Itoa(id)
}

// 递增函数
func increment() {
	defer wg.Done() // 协程结束时调用Done

	for i := 0; i < 1000; i++ {
		atomic.AddInt64(&counter, 1)
		// 每100次打印一次
		if (i+1)%100 == 0 {
			fmt.Printf("协程 %s - 计数：%d\n", getGoroutineID(), atomic.LoadInt64(&counter))
		}
	}
}

func main() {
	fmt.Println("=== 原子操作并发安全演示 ===")
	fmt.Println("启动10个协程，每个协程递增1000次")
	fmt.Println("预期结果：10000")
	fmt.Println()

	startTime := time.Now()

	// 启动10个协程
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go increment()
	}

	wg.Wait()
	endTime := time.Now()
	fmt.Printf("执行时间：%v\n", endTime.Sub(startTime))
	fmt.Printf("最终计数器值：%d\n", atomic.LoadInt64(&counter))
}
