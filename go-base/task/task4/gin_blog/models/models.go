package models

import (
	"gorm.io/gorm"
)

// User 用户模型
type User struct {
	gorm.Model
	Username string `gorm:"unique;not null" json:"username"`
	Password string `gorm:"not null" json:"-"` // json:"-" 表示不在JSON中显示密码
	Email    string `gorm:"unique;not null" json:"email"`
	Posts    []Post `gorm:"foreignKey:UserID" json:"posts,omitempty"`
	Comments []Comment `gorm:"foreignKey:UserID" json:"comments,omitempty"`
}

// Post 文章模型
type Post struct {
	gorm.Model
	Title    string    `gorm:"not null" json:"title"`
	Content  string    `gorm:"not null" json:"content"`
	UserID   uint      `gorm:"not null" json:"user_id"`
	User     User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Comments []Comment `gorm:"foreignKey:PostID" json:"comments,omitempty"`
}

// Comment 评论模型
type Comment struct {
	gorm.Model
	Content string `gorm:"not null" json:"content"`
	UserID  uint   `gorm:"not null" json:"user_id"`
	User    User   `gorm:"foreignKey:UserID" json:"user,omitempty"`
	PostID  uint   `gorm:"not null" json:"post_id"`
	Post    Post   `gorm:"foreignKey:PostID" json:"post,omitempty"`
}

// UserRegisterRequest 用户注册请求结构
type UserRegisterRequest struct {
	Username string `json:"username" binding:"required,min=3,max=20"`
	Password string `json:"password" binding:"required,min=6"`
	Email    string `json:"email" binding:"required,email"`
}

// UserLoginRequest 用户登录请求结构
type UserLoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// PostCreateRequest 创建文章请求结构
type PostCreateRequest struct {
	Title   string `json:"title" binding:"required,min=1,max=200"`
	Content string `json:"content" binding:"required,min=1"`
}

// PostUpdateRequest 更新文章请求结构
type PostUpdateRequest struct {
	Title   string `json:"title" binding:"omitempty,min=1,max=200"`
	Content string `json:"content" binding:"omitempty,min=1"`
}

// CommentCreateRequest 创建评论请求结构
type CommentCreateRequest struct {
	Content string `json:"content" binding:"required,min=1,max=500"`
	PostID  uint   `json:"post_id" binding:"required"`
}

// JWTClaims JWT声明结构
type JWTClaims struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
	Exp      int64  `json:"exp"`
}

// Response 统一响应结构
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// PaginationQuery 分页查询结构
type PaginationQuery struct {
	Page     int `form:"page,default=1" binding:"min=1"`
	PageSize int `form:"page_size,default=10" binding:"min=1,max=100"`
}

// PaginationResponse 分页响应结构
type PaginationResponse struct {
	Total    int64       `json:"total"`
	Page     int         `json:"page"`
	PageSize int         `json:"page_size"`
	Data     interface{} `json:"data"`
}