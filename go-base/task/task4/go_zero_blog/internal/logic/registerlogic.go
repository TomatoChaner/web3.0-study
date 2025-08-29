package logic

import (
	"context"
	"errors"
	"regexp"

	"go_zero_blog/internal/model"
	"go_zero_blog/internal/svc"
	"go_zero_blog/internal/types"
	"go_zero_blog/internal/utils"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type RegisterLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewRegisterLogic(ctx context.Context, svcCtx *svc.ServiceContext) *RegisterLogic {
	return &RegisterLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *RegisterLogic) Register(req *types.RegisterReq) (resp *types.BaseResp, err error) {
	// 参数验证
	if err := l.validateRegisterReq(req); err != nil {
		return &types.BaseResp{
			Code:    400,
			Message: err.Error(),
		}, nil
	}

	// 检查用户名是否已存在
	var existingUser model.User
	result := l.svcCtx.DB.Where("username = ? OR email = ?", req.Username, req.Email).First(&existingUser)
	if result.Error == nil {
		return &types.BaseResp{
			Code:    400,
			Message: "用户名或邮箱已存在",
		}, nil
	} else if !errors.Is(result.Error, gorm.ErrRecordNotFound) {
		logx.Errorf("查询用户失败: %v", result.Error)
		return &types.BaseResp{
			Code:    500,
			Message: "服务器内部错误",
		}, nil
	}

	// 加密密码
	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		logx.Errorf("密码加密失败: %v", err)
		return &types.BaseResp{
			Code:    500,
			Message: "服务器内部错误",
		}, nil
	}

	// 创建用户
	user := model.User{
		Username: req.Username,
		Email:    req.Email,
		Password: hashedPassword,
	}

	if err := l.svcCtx.DB.Create(&user).Error; err != nil {
		logx.Errorf("创建用户失败: %v", err)
		return &types.BaseResp{
			Code:    500,
			Message: "服务器内部错误",
		}, nil
	}

	return &types.BaseResp{
		Code:    200,
		Message: "注册成功",
	}, nil
}

// validateRegisterReq 验证注册请求参数
func (l *RegisterLogic) validateRegisterReq(req *types.RegisterReq) error {
	if req.Username == "" {
		return errors.New("用户名不能为空")
	}
	if len(req.Username) < 3 || len(req.Username) > 20 {
		return errors.New("用户名长度必须在3-20个字符之间")
	}
	if req.Email == "" {
		return errors.New("邮箱不能为空")
	}
	// 简单的邮箱格式验证
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	if !emailRegex.MatchString(req.Email) {
		return errors.New("邮箱格式不正确")
	}
	if req.Password == "" {
		return errors.New("密码不能为空")
	}
	if len(req.Password) < 6 {
		return errors.New("密码长度不能少于6个字符")
	}
	return nil
}
