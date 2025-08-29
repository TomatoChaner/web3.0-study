package logic

import (
	"context"
	"errors"

	"go_zero_blog/internal/model"
	"go_zero_blog/internal/svc"
	"go_zero_blog/internal/types"
	"go_zero_blog/internal/utils"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type LoginLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewLoginLogic(ctx context.Context, svcCtx *svc.ServiceContext) *LoginLogic {
	return &LoginLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *LoginLogic) Login(req *types.LoginReq) (resp *types.LoginResp, err error) {
	// 参数验证
	if req.Username == "" || req.Password == "" {
		return nil, errors.New("用户名和密码不能为空")
	}

	// 查找用户
	var user model.User
	result := l.svcCtx.DB.Where("username = ? OR email = ?", req.Username, req.Username).First(&user)
	if errors.Is(result.Error, gorm.ErrRecordNotFound) {
		return nil, errors.New("用户名或密码错误")
	} else if result.Error != nil {
		logx.Errorf("查询用户失败: %v", result.Error)
		return nil, errors.New("服务器内部错误")
	}

	// 验证密码
	if !utils.CheckPassword(user.Password, req.Password) {
		return nil, errors.New("用户名或密码错误")
	}

	// 生成JWT令牌
	token, err := utils.GenerateToken(user.ID, user.Username, l.svcCtx.Config.JWT)
	if err != nil {
		logx.Errorf("生成JWT令牌失败: %v", err)
		return nil, errors.New("服务器内部错误")
	}

	return &types.LoginResp{
		Token: token,
		UserInfo: types.UserInfo{
			Id:        int64(user.ID),
			Username:  user.Username,
			Email:     user.Email,
			CreatedAt: user.CreatedAt.Format("2006-01-02 15:04:05"),
		},
	}, nil
}
