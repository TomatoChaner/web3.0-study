package logic

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"

	"go_zero_blog/internal/model"
	"go_zero_blog/internal/svc"
	"go_zero_blog/internal/types"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type GetUserInfoLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetUserInfoLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetUserInfoLogic {
	return &GetUserInfoLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetUserInfoLogic) GetUserInfo() (resp *types.UserInfo, err error) {
	// 从context中获取用户ID
	userIDValue := l.ctx.Value("user_id")
	if userIDValue == nil {
		return nil, errors.New("用户未认证")
	}

	// JWT claims中的数字通常被解析为json.Number或float64
	var userID uint
	switch v := userIDValue.(type) {
	case json.Number:
		// 处理json.Number类型
		id, err := v.Int64()
		if err != nil {
			return nil, errors.New("无效的用户ID格式")
		}
		userID = uint(id)
	case float64:
		userID = uint(v)
	case uint:
		userID = v
	case int:
		userID = uint(v)
	case string:
		id, err := strconv.ParseUint(v, 10, 32)
		if err != nil {
			return nil, errors.New("无效的用户ID格式")
		}
		userID = uint(id)
	default:
		return nil, errors.New("无效的用户ID类型")
	}

	// 查询用户信息
	var user model.User
	result := l.svcCtx.DB.First(&user, userID)
	if errors.Is(result.Error, gorm.ErrRecordNotFound) {
		return nil, errors.New("用户不存在")
	} else if result.Error != nil {
		logx.Errorf("查询用户失败: %v", result.Error)
		return nil, errors.New("服务器内部错误")
	}

	return &types.UserInfo{
		Id:        int64(user.ID),
		Username:  user.Username,
		Email:     user.Email,
		CreatedAt: user.CreatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}
