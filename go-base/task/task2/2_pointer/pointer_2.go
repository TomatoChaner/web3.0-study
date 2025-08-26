package main

/*
题目 ：实现一个函数，接收一个整数切片的指针，将切片中的每个元素乘以2。
考察点 ：指针运算、切片操作。
*/
import (
	"fmt"
)

// doubleSlice 函数接收一个指向切片的指针，将切片中每个元素的值翻倍
// 参数: slice - 指向整数切片的指针
func doubleSlice(slice *[]int){
	// 遍历切片中的每个元素
	for i:=0;i<len(*slice);i++{
		// 通过指针解引用访问切片，将第i个元素的值乘以2
		// (*slice)[i] 表示先解引用指针得到切片，再访问第i个元素
		(*slice)[i] *=2
	}
}

// main 函数演示doubleSlice函数的使用
func main() {
	// 创建一个整数切片
	slice := []int{1, 2, 3, 4, 5}
	fmt.Println("原始切片:", slice)
	
	// 调用doubleSlice函数，传入切片的指针
	doubleSlice(&slice)
	fmt.Println("翻倍后的切片:", slice)
}
