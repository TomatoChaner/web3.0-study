package controllers

import (
	"gin_blog/config"
	"gin_blog/models"
	"gin_blog/utils"
	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// UserController 用户控制器
type UserController struct{}

// NewUserController 创建用户控制器实例
func NewUserController() *UserController {
	return &UserController{}
}

// Register 用户注册
func (uc *UserController) Register(c *gin.Context) {
	var req models.UserRegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	// 检查用户名是否已存在
	var existingUser models.User
	db := config.GetDB()
	if err := db.Where("username = ?", req.Username).First(&existingUser).Error; err == nil {
		utils.BadRequestResponse(c, "用户名已存在")
		return
	}

	// 检查邮箱是否已存在
	if err := db.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		utils.BadRequestResponse(c, "邮箱已被注册")
		return
	}

	// 加密密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		logrus.WithError(err).Error("Failed to hash password")
		utils.InternalServerErrorResponse(c, "密码加密失败")
		return
	}

	// 创建用户
	user := models.User{
		Username: req.Username,
		Password: string(hashedPassword),
		Email:    req.Email,
	}

	if err := db.Create(&user).Error; err != nil {
		logrus.WithError(err).Error("Failed to create user")
		utils.InternalServerErrorResponse(c, "用户创建失败")
		return
	}

	logrus.WithFields(logrus.Fields{
		"user_id":  user.ID,
		"username": user.Username,
	}).Info("User registered successfully")

	utils.SuccessWithMessage(c, "用户注册成功", gin.H{
		"user_id":  user.ID,
		"username": user.Username,
		"email":    user.Email,
	})
}

// Login 用户登录
func (uc *UserController) Login(c *gin.Context) {
	var req models.UserLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	// 查找用户
	var user models.User
	db := config.GetDB()
	if err := db.Where("username = ?", req.Username).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.UnauthorizedResponse(c, "用户名或密码错误")
		} else {
			logrus.WithError(err).Error("Database error during login")
			utils.InternalServerErrorResponse(c, "登录失败")
		}
		return
	}

	// 验证密码
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		utils.UnauthorizedResponse(c, "用户名或密码错误")
		return
	}

	// 生成JWT令牌
	token, err := utils.GenerateToken(user.ID, user.Username)
	if err != nil {
		logrus.WithError(err).Error("Failed to generate token")
		utils.InternalServerErrorResponse(c, "令牌生成失败")
		return
	}

	logrus.WithFields(logrus.Fields{
		"user_id":  user.ID,
		"username": user.Username,
	}).Info("User logged in successfully")

	utils.SuccessWithMessage(c, "登录成功", gin.H{
		"token":    token,
		"user_id":  user.ID,
		"username": user.Username,
		"email":    user.Email,
	})
}

// GetProfile 获取用户信息
func (uc *UserController) GetProfile(c *gin.Context) {
	userID := c.GetUint("user_id")
	if userID == 0 {
		utils.UnauthorizedResponse(c, "未找到用户信息")
		return
	}

	var user models.User
	db := config.GetDB()
	if err := db.First(&user, userID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.NotFoundResponse(c, "用户不存在")
		} else {
			logrus.WithError(err).Error("Database error when getting user profile")
			utils.InternalServerErrorResponse(c, "获取用户信息失败")
		}
		return
	}

	utils.SuccessResponse(c, gin.H{
		"user_id":    user.ID,
		"username":   user.Username,
		"email":      user.Email,
		"created_at": user.CreatedAt,
	})
}