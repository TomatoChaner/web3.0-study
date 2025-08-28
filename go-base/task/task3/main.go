package main

import (
	"fmt"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

func main() {
	// 连接数据库
	dsn := "root:lh123456@tcp(127.0.0.1:3306)/go_base_task3?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		fmt.Printf("数据库连接失败: %v\n", err)
		return
	}
	fmt.Println("数据库连接成功")
	// //题目1：基本CRUD操作
	// //自动迁移:如果数据库中不存在 students 表，会自动创建
	// db.AutoMigrate(&Student{})
	// // 插入数据:向 students 表中插入一条新记录，学生姓名为 "张三"，年龄为 20，年级为 "三年级"
	// db.Debug().Create(&Student{Name: "张三", Age: 20, Grade: "三年级"})
	// // 查询数据:查询 students 表中所有年龄大于 18 岁的学生信息
	// var students []Student
	// db.Debug().Where("age > ?", 18).Find(&students)
	// // 更新数据:将 students 表中姓名为 "张三" 的学生年级更新为 "四年级"
	// db.Debug().Model(&Student{}).Where("name = ?", "张三").Update("grade", "四年级")
	// fmt.Println("更新数据完成")
	// // 删除数据:删除 students 表中年龄小于 15 岁的学生记录
	// db.Debug().Delete(&Student{}, "age < ?", 15)
	// fmt.Println("删除数据完成")

	// //题目2：事务语句
	// db.AutoMigrate(&Account{}, &Transaction{})
	// var count int64
	// db.Model(&Account{}).Count(&count)
	// if count == 0 {
	// 	db.Create(&Account{ID: 1, Balance: 1000})
	// 	db.Create(&Account{ID: 2, Balance: 500})
	// }
	// // 转账：从账户1转账100到账户2
	// err = Transfer(db, 1, 2, 100)
	// if err != nil {
	// 	fmt.Println("转账失败:", err)
	// } else {
	// 	fmt.Println("转账成功")
	// }
	// // 转账: 从账户2转账50到账户1
	// err = Transfer(db, 2, 1, 50)
	// if err != nil {
	// 	fmt.Println("转账失败:", err)
	// } else {
	// 	fmt.Println("转账成功")
	// }

	// 	Sqlx入门
	// 题目1：使用SQL扩展库进行查询
	//使用Sqlx查询 employees 表中所有部门为 "技术部" 的员工信息，并将结果映射到一个自定义的 Employee 结构体切片中
	// db.AutoMigrate(&Employee{})
	// db.Create(&Employee{ID: 1, Name: "John", Department: "技术部", Salary: 30000})
	// db.Create(&Employee{ID: 2, Name: "Tom", Department: "技术部", Salary: 40000})
	// db.Create(&Employee{ID: 3, Name: "Jerry", Department: "销售部", Salary: 60000})
	// var employees []Employee
	// err = db.Raw("SELECT * FROM employees WHERE department = ?", "技术部").Scan(&employees).Error
	// if err != nil {
	// 	fmt.Printf("Sqlx查询失败: %v\n", err)
	// 	return
	// }
	// fmt.Println("查询结果:", employees)
	// //查询 employees 表中工资最高的员工信息，并将结果映射到一个 Employee 结构体中.
	// var employee Employee
	// err = db.Raw("SELECT * FROM employees ORDER BY salary DESC LIMIT 1").Scan(&employee).Error
	// if err != nil {
	// 	fmt.Printf("Sqlx查询失败: %v\n", err)
	// 	return
	// }
	// fmt.Println("查询结果:", employee)

	//题目2：实现类型安全映射
	// //使用Sqlx执行一个复杂的查询，例如查询价格大于 50 元的书籍，并将结果映射到 Book 结构体切片中，确保类型安全
	// db.AutoMigrate(&Book{})

	// // 批量插入数据（如果需要避免重复可以加条件判断）
	// booksToInsert := []Book{
	// 	{ID: 1, Title: "Go 语言入门", Author: "John", Price: 49.99},
	// 	{ID: 2, Title: "Java 语言入门", Author: "Jerry", Price: 69.99},
	// 	{ID: 3, Title: "Python 语言入门", Author: "Tom", Price: 79.99},
	// }
	// result := db.CreateInBatches(booksToInsert, 100)
	// if result.Error != nil {
	// 	fmt.Printf("批量插入书籍失败: %v\n", result.Error)
	// 	// 可以选择继续执行或返回，这里选择继续
	// } else {
	// 	fmt.Printf("成功插入 %d 条书籍记录\n", result.RowsAffected)
	// }

	// var books []Book
	// query := "SELECT id, title, author, price FROM books WHERE price > ?"

	// // 正确使用 ? 占位符并传参
	// err = db.Raw(query, 50).Scan(&books).Error
	// if err != nil {
	// 	log.Fatalln("查询书籍失败:", err)
	// }

	// fmt.Println("价格大于50的书籍:")
	// for _, book := range books {
	// 	fmt.Printf("ID: %d, Title: %s, Author: %s, Price: %.2f\n", book.ID, book.Title, book.Author, book.Price)
	// }
	// 	进阶gorm
	// 题目1：模型定义
	// 使用Gorm创建这些模型对应的数据库表
	db.AutoMigrate(&User{}, &Post{}, &Comment{})
	if err != nil {
		log.Fatalln("Faild to migrate database:", err)
	}
	log.Println("Database migrated successfully")
	// seedData(db)
	//题目2：关联查询
	// 基于上述博客系统的模型定义。
	// 要求 ：
	// 使用Gorm查询某个用户发布的所有文章及其对应的评论信息。
	var user User
	db.Preload("Posts").Preload("Posts.Comments").First(&user, 2)
	fmt.Printf("用户信息: %s (%s)\n", user.Name, user.Email)
	for _, post := range user.Posts {
		fmt.Printf("  文章: %s, 评论数: %d\n", post.Title, len(post.Comments))
		for _, comment := range post.Comments {
			fmt.Printf("    评论: %s\n", comment.Content)
		}
	}

	// 使用Gorm查询评论数量最多的文章信息。
	var post Post
	db.Table("posts").
		Select("posts.*, COUNT(comments.id) as comment_count").
		Joins("LEFT JOIN comments ON posts.id = comments.post_id").
		Group("posts.id").
		Order("comment_count DESC").
		Preload("Comments").
		First(&post)
	fmt.Printf("评论最多的文章: %s, 评论数: %d\n", post.Title, len(post.Comments))
	for _, comment := range post.Comments {
		fmt.Printf("  评论: %s\n", comment.Content)
	}

	//题目3：钩子函数
	// 继续使用博客系统的模型。
	// 要求 ：
	// 为 Post 模型添加一个钩子函数，在文章创建时自动更新用户的文章数量统计字段。
	// 为 Comment 模型添加一个钩子函数，在评论删除时检查文章的评论数量，如果评论数量为 0，则更新文章的评论状态为 "无评论"。

	fmt.Println("\n=== 钩子函数演示 ===")

	// 演示Post创建钩子：创建新文章时自动更新用户文章数量
	fmt.Println("\n1. 创建新文章前的用户文章数量：")
	var userBefore User
	db.First(&userBefore, 1)
	fmt.Printf("用户 %s 的文章数量: %d\n", userBefore.Name, userBefore.PostsCount)

	// 创建新文章（触发AfterCreate钩子）
	newPost := Post{
		Title:   "钩子函数测试文章",
		Content: "这是一篇用于测试钩子函数的文章",
		UserID:  1,
	}
	if err := db.Create(&newPost).Error; err != nil {
		fmt.Printf("创建文章失败: %v\n", err)
	} else {
		fmt.Println("文章创建成功！")
	}

	// 检查用户文章数量是否自动更新
	fmt.Println("\n2. 创建新文章后的用户文章数量：")
	var userAfter User
	db.First(&userAfter, 1)
	fmt.Printf("用户 %s 的文章数量: %d\n", userAfter.Name, userAfter.PostsCount)

	// 演示Comment删除钩子：删除评论时自动更新文章评论状态
	fmt.Println("\n3. 删除评论前的文章状态：")
	var postBefore Post
	db.Preload("Comments").First(&postBefore, newPost.ID)
	fmt.Printf("文章 '%s' 的评论状态: %s, 评论数量: %d\n", postBefore.Title, postBefore.CommentStatus, len(postBefore.Comments))

	// 为新文章添加评论
	newComment := Comment{
		Content: "这是一条测试评论",
		PostID:  newPost.ID,
	}
	db.Create(&newComment)
	fmt.Println("添加了一条评论")

	// 检查文章状态
	var postWithComment Post
	db.Preload("Comments").First(&postWithComment, newPost.ID)
	fmt.Printf("文章 '%s' 的评论状态: %s, 评论数量: %d\n", postWithComment.Title, postWithComment.CommentStatus, len(postWithComment.Comments))

	// 删除评论（触发AfterDelete钩子）
	if err := db.Delete(&newComment).Error; err != nil {
		fmt.Printf("删除评论失败: %v\n", err)
	} else {
		fmt.Println("\n4. 删除评论后的文章状态：")
	}

	// 检查文章评论状态是否自动更新
	var postAfterDelete Post
	db.Preload("Comments").First(&postAfterDelete, newPost.ID)
	fmt.Printf("文章 '%s' 的评论状态: %s, 评论数量: %d\n", postAfterDelete.Title, postAfterDelete.CommentStatus, len(postAfterDelete.Comments))

}
