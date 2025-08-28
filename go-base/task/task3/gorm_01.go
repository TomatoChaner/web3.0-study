/*
题目1：模型定义
假设你要开发一个博客系统，有以下几个实体： User （用户）、 Post （文章）、 Comment （评论）。
要求 ：
使用Gorm定义 User 、 Post 和 Comment 模型，其中 User 与 Post 是一对多关系（一个用户可以发布多篇文章）， Post 与 Comment 也是一对多关系（一篇文章可以有多个评论）。
编写Go代码，使用Gorm创建这些模型对应的数据库表。
*/
package main

import (
	"fmt"

	"gorm.io/gorm"
)

// User 与 Post 是一对多关系，一个用户可以发布多篇文章
// Post 与 Comment 也是一对多关系，一篇文章可以有多个评论
// 用户有文章数量统计字段
type User struct {
	ID         uint `gorm:"primaryKey"`
	Name       string
	Email      string
	PostsCount int    `gorm:"default:0"`         // 文章数量统计字段
	Posts      []Post `gorm:"foreignKey:UserID"` // 一对多关系：一个用户可以有多篇文章
}

type Post struct {
	ID            uint `gorm:"primaryKey"`
	Title         string
	Content       string
	UserID        uint      `gorm:"not null"`          // 外键，关联到User表
	User          User      `gorm:"foreignKey:UserID"` // 属于关系：文章属于某个用户
	Comments      []Comment `gorm:"foreignKey:PostID"` // 一对多关系：一篇文章可以有多个评论
	CommentStatus string    `gorm:"size:50;default:'无评论'"`
}

// AfterCreate 钩子函数：文章创建后自动更新用户的文章数量
func (p *Post) AfterCreate(tx *gorm.DB) (err error) {
	// 更新用户的文章数量
	return tx.Model(&User{}).Where("id = ?", p.UserID).UpdateColumn("posts_count", gorm.Expr("posts_count + ?", 1)).Error
}

type Comment struct {
	ID      uint `gorm:"primaryKey"`
	Content string
	PostID  uint `gorm:"not null"`          // 外键，关联到Post表
	Post    Post `gorm:"foreignKey:PostID"` // 属于关系：评论属于某篇文章
}

// AfterDelete 钩子函数：评论删除后检查和更新文章的评论状态
func (c *Comment) AfterDelete(tx *gorm.DB) (err error) {
	// 检查该文章是否还有其他评论
	var count int64
	if err := tx.Model(&Comment{}).Where("post_id = ?", c.PostID).Count(&count).Error; err != nil {
		return err
	}

	// 根据评论数量更新文章的评论状态
	var status string
	if count == 0 {
		status = "无评论"
	} else {
		status = "有评论"
	}

	return tx.Model(&Post{}).Where("id = ?", c.PostID).UpdateColumn("comment_status", status).Error
}

func seedData(db *gorm.DB) error {
	// 批量创建用户数据
	users := []User{
		{Name: "Alice", Email: "alice@example.com"},
		{Name: "Bob", Email: "bob@example.com"},
		{Name: "Charlie", Email: "charlie@example.com"},
	}

	if err := db.Create(&users).Error; err != nil {
		return fmt.Errorf("创建用户失败: %w", err)
	}

	// 使用GORM关联创建文章和评论
	postsData := []Post{
		{
			Title:   "Go语言入门指南",
			Content: "Go是一门现代化的编程语言...",
			UserID:  users[0].ID,
			Comments: []Comment{
				{Content: "很好的入门教程！"},
				{Content: "感谢分享"},
				{Content: "感谢大大"},
			},
		},
		{
			Title:   "数据库设计最佳实践",
			Content: "在设计数据库时需要考虑...",
			UserID:  users[1].ID,
			Comments: []Comment{
				{Content: "非常实用的建议"},
				{Content: "学到了很多"},
			},
		},
		{
			Title:   "微服务架构思考",
			Content: "微服务架构的优缺点分析...",
			UserID:  users[2].ID,
			Comments: []Comment{
				{Content: "深度好文"},
			},
		},
	}

	// 使用GORM的关联创建功能，一次性创建文章及其评论
	for _, post := range postsData {
		if err := db.Create(&post).Error; err != nil {
			return fmt.Errorf("创建文章失败: %w", err)
		}
	}

	fmt.Println("数据初始化完成！")
	fmt.Printf("创建了 %d 个用户\n", len(users))
	fmt.Printf("创建了 %d 篇文章\n", len(postsData))

	return nil
}
