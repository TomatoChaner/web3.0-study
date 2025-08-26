package main

/*
题目 ：设计一个任务调度器，接收一组任务（可以用函数表示），
并使用协程并发执行这些任务，同时统计每个任务的执行时间。
考察点 ：协程原理、并发任务调度。
*/

import (
	"fmt"
	"sync"
	"time"
)

func taskScheduler(tasks []func(), taskNames []string) {
	var wg sync.WaitGroup
	for i, task := range tasks {
		wg.Add(1)
		go func(t func(), name string) {
			defer wg.Done()
			start := time.Now()
			t()
			duration := time.Since(start)
			fmt.Printf("%s 执行时间: %v\n", name, duration)
		}(task, taskNames[i])
	}
	wg.Wait()
}
func main() {
	fmt.Println("=== 测试 groutine 函数 ===")
	// 定义一组任务
	tasks := []func(){
		func() {
			fmt.Println("任务1: 吃饭")
			time.Sleep(2 * time.Second)
		},
		func() {
			fmt.Println("任务2: 工作")
			time.Sleep(3 * time.Second)
		},
		func() {
			fmt.Println("任务3: 摸鱼")
			time.Sleep(1 * time.Second)
		},
	}

	// 任务名称
	taskNames := []string{"任务1", "任务2", "任务3"}

	// 调用任务调度器并统计每个任务执行时间
	start := time.Now()
	taskScheduler(tasks, taskNames)
	totalDuration := time.Since(start)

	fmt.Printf("\n所有任务总执行时间: %v\n", totalDuration)
}
