package controllers

import (
	"strconv"

	"gin_blog/config"
	"gin_blog/middleware"
	"gin_blog/models"
	"gin_blog/utils"
	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

// PostController 文章控制器
type PostController struct{}

// NewPostController 创建文章控制器实例
func NewPostController() *PostController {
	return &PostController{}
}

// CreatePost 创建文章
func (pc *PostController) CreatePost(c *gin.Context) {
	var req models.PostCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	userID := middleware.GetCurrentUserID(c)
	if userID == 0 {
		utils.UnauthorizedResponse(c, "未找到用户信息")
		return
	}

	// 创建文章
	post := models.Post{
		Title:   req.Title,
		Content: req.Content,
		UserID:  userID,
	}

	db := config.GetDB()
	if err := db.Create(&post).Error; err != nil {
		logrus.WithError(err).Error("Failed to create post")
		utils.InternalServerErrorResponse(c, "文章创建失败")
		return
	}

	// 预加载用户信息
	db.Preload("User").First(&post, post.ID)

	logrus.WithFields(logrus.Fields{
		"post_id": post.ID,
		"user_id": userID,
		"title":   post.Title,
	}).Info("Post created successfully")

	utils.SuccessWithMessage(c, "文章创建成功", post)
}

// GetPosts 获取文章列表
func (pc *PostController) GetPosts(c *gin.Context) {
	var query models.PaginationQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	db := config.GetDB()
	var posts []models.Post
	var total int64

	// 计算总数
	db.Model(&models.Post{}).Count(&total)

	// 分页查询
	offset := (query.Page - 1) * query.PageSize
	if err := db.Preload("User").Offset(offset).Limit(query.PageSize).Order("created_at DESC").Find(&posts).Error; err != nil {
		logrus.WithError(err).Error("Failed to get posts")
		utils.InternalServerErrorResponse(c, "获取文章列表失败")
		return
	}

	response := models.PaginationResponse{
		Total:    total,
		Page:     query.Page,
		PageSize: query.PageSize,
		Data:     posts,
	}

	utils.SuccessResponse(c, response)
}

// GetPost 获取单个文章
func (pc *PostController) GetPost(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		utils.BadRequestResponse(c, "无效的文章ID")
		return
	}

	var post models.Post
	db := config.GetDB()
	if err := db.Preload("User").Preload("Comments.User").First(&post, postID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.NotFoundResponse(c, "文章不存在")
		} else {
			logrus.WithError(err).Error("Database error when getting post")
			utils.InternalServerErrorResponse(c, "获取文章失败")
		}
		return
	}

	utils.SuccessResponse(c, post)
}

// UpdatePost 更新文章
func (pc *PostController) UpdatePost(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		utils.BadRequestResponse(c, "无效的文章ID")
		return
	}

	var req models.PostUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	userID := middleware.GetCurrentUserID(c)
	if userID == 0 {
		utils.UnauthorizedResponse(c, "未找到用户信息")
		return
	}

	// 查找文章
	var post models.Post
	db := config.GetDB()
	if err := db.First(&post, postID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.NotFoundResponse(c, "文章不存在")
		} else {
			logrus.WithError(err).Error("Database error when finding post")
			utils.InternalServerErrorResponse(c, "查找文章失败")
		}
		return
	}

	// 检查权限
	if post.UserID != userID {
		utils.ForbiddenResponse(c, "无权限修改此文章")
		return
	}

	// 更新文章
	updateData := make(map[string]interface{})
	if req.Title != "" {
		updateData["title"] = req.Title
	}
	if req.Content != "" {
		updateData["content"] = req.Content
	}

	if err := db.Model(&post).Updates(updateData).Error; err != nil {
		logrus.WithError(err).Error("Failed to update post")
		utils.InternalServerErrorResponse(c, "文章更新失败")
		return
	}

	// 重新加载文章数据
	db.Preload("User").First(&post, postID)

	logrus.WithFields(logrus.Fields{
		"post_id": post.ID,
		"user_id": userID,
	}).Info("Post updated successfully")

	utils.SuccessWithMessage(c, "文章更新成功", post)
}

// DeletePost 删除文章
func (pc *PostController) DeletePost(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		utils.BadRequestResponse(c, "无效的文章ID")
		return
	}

	userID := middleware.GetCurrentUserID(c)
	if userID == 0 {
		utils.UnauthorizedResponse(c, "未找到用户信息")
		return
	}

	// 查找文章
	var post models.Post
	db := config.GetDB()
	if err := db.First(&post, postID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.NotFoundResponse(c, "文章不存在")
		} else {
			logrus.WithError(err).Error("Database error when finding post")
			utils.InternalServerErrorResponse(c, "查找文章失败")
		}
		return
	}

	// 检查权限
	if post.UserID != userID {
		utils.ForbiddenResponse(c, "无权限删除此文章")
		return
	}

	// 删除文章（软删除）
	if err := db.Delete(&post).Error; err != nil {
		logrus.WithError(err).Error("Failed to delete post")
		utils.InternalServerErrorResponse(c, "文章删除失败")
		return
	}

	logrus.WithFields(logrus.Fields{
		"post_id": post.ID,
		"user_id": userID,
	}).Info("Post deleted successfully")

	utils.SuccessWithMessage(c, "文章删除成功", nil)
}