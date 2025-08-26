package main

/*
题目 ：编写一个程序，使用通道实现两个协程之间的通信。
一个协程生成从1到10的整数，并将这些整数发送到通道中，
另一个协程从通道中接收这些整数并打印出来。
考察点 ：通道的基本使用、协程间通信。
*/
import (
	"fmt"
	"time"
)

func send(ch chan int) {
	fmt.Println("发送协程开始")
	for i := 1; i <= 10; i++ {
		fmt.Println("发送:", i)
		ch <- i
		time.Sleep(time.Second)
	}
	fmt.Println("发送协程结束")
	close(ch)
}
func receive(ch chan int) {
	fmt.Println("接收协程开始")
	for i := range ch {
		fmt.Println("接收:", i)
	}
	fmt.Println("接收协程结束")
}
func main() {
	ch := make(chan int)
	go send(ch)
	go receive(ch)
	time.Sleep(time.Second * 11)
}
