package main

/*
题目 ：定义一个 Shape 接口，包含 Area() 和 Perimeter() 两个方法。
然后创建 Rectangle 和 Circle 结构体，实现 Shape 接口。
在主函数中，创建这两个结构体的实例，并调用它们的 Area() 和 Perimeter() 方法。
考察点 ：接口的定义与实现、面向对象编程风格。
*/
import (
	"fmt"
	"math"
)

type Shape interface {
	Area() float64
	Perimeter() float64
}

type Rectangle struct {
	Width  float64
	Height float64
}

func (r Rectangle) Area() float64 {
	return r.Width * r.Height
}

func (r Rectangle) Perimeter() float64 {
	return 2 * (r.Width + r.Height)
}

type Circle struct {
	Radius float64
}

func (c Circle) Area() float64 {
	return math.Pi * c.Radius * c.Radius
}

func (c Circle) Perimeter() float64 {
	return 2 * math.Pi * c.Radius
}
func main() {
	fmt.Println("=== 测试 object_oriented 函数 ===")
	// 创建 Rectangle 实例
	rect := Rectangle{Width: 5, Height: 3}
	fmt.Printf("矩形的面积: %v\n", rect.Area())
	fmt.Printf("矩形的周长: %v\n", rect.Perimeter())
	// 创建 Circle 实例
	circle := Circle{Radius: 2}
	fmt.Printf("圆的面积: %v\n", circle.Area())
	fmt.Printf("圆的周长: %v\n", circle.Perimeter())
}
