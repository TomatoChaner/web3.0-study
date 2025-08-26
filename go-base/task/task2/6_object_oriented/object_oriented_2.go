package main

/*
题目 ：使用组合的方式创建一个 Person 结构体，
包含 Name 和 Age 字段，再创建一个 Employee 结构体，
组合 Person 结构体并添加 EmployeeID 字段。
为 Employee 结构体实现一个 PrintInfo() 方法，输出员工的信息。
考察点 ：组合的使用、方法接收者。
*/
import (
	"fmt"
)

type Person struct {
	Name string
	Age  int
}

type Employee struct {
	Person
	EmployeeID int
}

// PrintInfo 输出员工的信息
func (e Employee) PrintInfo() {
	fmt.Printf("姓名: %s, 年龄: %d, 员工ID: %d\n", e.Name, e.Age, e.EmployeeID)
}

// main 主函数，测试所有算法函数
func main() {
	fmt.Println("=== 测试 object_oriented_2 函数 ===")
	// 创建 Employee 实例
	emp := Employee{
		Person: Person{
			Name: "张三",
			Age:  30,
		},
		EmployeeID: 1001,
	}
	// 调用 PrintInfo 方法输出员工信息
	emp.PrintInfo()
}