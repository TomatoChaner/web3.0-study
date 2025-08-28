/*
假设你已经使用Sqlx连接到一个数据库，
并且有一个 employees 表，包含字段 id 、 name 、 department 、 salary 。
要求 ：
编写Go代码，使用Sqlx查询 employees 表中所有部门为 "技术部" 的员工信息，
并将结果映射到一个自定义的 Employee 结构体切片中。
编写Go代码，使用Sqlx查询 employees 表中工资最高的员工信息，
并将结果映射到一个 Employee 结构体中。
*/
package main

type Employee struct {
	ID         uint `gorm:"primaryKey"`
	Name       string
	Department string
	Salary     uint
}
