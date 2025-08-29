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

// CommentController 评论控制器
type CommentController struct{}

// NewCommentController 创建评论控制器实例
func NewCommentController() *CommentController {
	return &CommentController{}
}

// CreateComment 创建评论
func (cc *CommentController) CreateComment(c *gin.Context) {
	var req models.CommentCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	userID := middleware.GetCurrentUserID(c)
	if userID == 0 {
		utils.UnauthorizedResponse(c, "未找到用户信息")
		return
	}

	// 检查文章是否存在
	var post models.Post
	db := config.GetDB()
	if err := db.First(&post, req.PostID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.NotFoundResponse(c, "文章不存在")
		} else {
			logrus.WithError(err).Error("Database error when finding post")
			utils.InternalServerErrorResponse(c, "查找文章失败")
		}
		return
	}

	// 创建评论
	comment := models.Comment{
		Content: req.Content,
		UserID:  userID,
		PostID:  req.PostID,
	}

	if err := db.Create(&comment).Error; err != nil {
		logrus.WithError(err).Error("Failed to create comment")
		utils.InternalServerErrorResponse(c, "评论创建失败")
		return
	}

	// 预加载用户信息
	db.Preload("User").First(&comment, comment.ID)

	logrus.WithFields(logrus.Fields{
		"comment_id": comment.ID,
		"post_id":    req.PostID,
		"user_id":    userID,
	}).Info("Comment created successfully")

	utils.SuccessWithMessage(c, "评论创建成功", comment)
}

// GetCommentsByPost 获取文章的评论列表
func (cc *CommentController) GetCommentsByPost(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("post_id"), 10, 32)
	if err != nil {
		utils.BadRequestResponse(c, "无效的文章ID")
		return
	}

	// 检查文章是否存在
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

	// 获取分页参数
	var query models.PaginationQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	var comments []models.Comment
	var total int64

	// 计算总数
	db.Model(&models.Comment{}).Where("post_id = ?", postID).Count(&total)

	// 分页查询评论
	offset := (query.Page - 1) * query.PageSize
	if err := db.Preload("User").Where("post_id = ?", postID).Offset(offset).Limit(query.PageSize).Order("created_at ASC").Find(&comments).Error; err != nil {
		logrus.WithError(err).Error("Failed to get comments")
		utils.InternalServerErrorResponse(c, "获取评论列表失败")
		return
	}

	response := models.PaginationResponse{
		Total:    total,
		Page:     query.Page,
		PageSize: query.PageSize,
		Data:     comments,
	}

	utils.SuccessResponse(c, response)
}

// DeleteComment 删除评论
func (cc *CommentController) DeleteComment(c *gin.Context) {
	commentID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		utils.BadRequestResponse(c, "无效的评论ID")
		return
	}

	userID := middleware.GetCurrentUserID(c)
	if userID == 0 {
		utils.UnauthorizedResponse(c, "未找到用户信息")
		return
	}

	// 查找评论
	var comment models.Comment
	db := config.GetDB()
	if err := db.First(&comment, commentID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.NotFoundResponse(c, "评论不存在")
		} else {
			logrus.WithError(err).Error("Database error when finding comment")
			utils.InternalServerErrorResponse(c, "查找评论失败")
		}
		return
	}

	// 检查权限（只有评论作者可以删除）
	if comment.UserID != userID {
		utils.ForbiddenResponse(c, "无权限删除此评论")
		return
	}

	// 删除评论（软删除）
	if err := db.Delete(&comment).Error; err != nil {
		logrus.WithError(err).Error("Failed to delete comment")
		utils.InternalServerErrorResponse(c, "评论删除失败")
		return
	}

	logrus.WithFields(logrus.Fields{
		"comment_id": comment.ID,
		"user_id":    userID,
	}).Info("Comment deleted successfully")

	utils.SuccessWithMessage(c, "评论删除成功", nil)
}