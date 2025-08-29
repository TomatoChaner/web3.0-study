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
)

type CreatePostLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewCreatePostLogic(ctx context.Context, svcCtx *svc.ServiceContext) *CreatePostLogic {
	return &CreatePostLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *CreatePostLogic) CreatePost(req *types.CreatePostReq) (resp *types.PostInfo, err error) {
	// 参数验证
	if req.Title == "" {
		return nil, errors.New("文章标题不能为空")
	}
	if req.Content == "" {
		return nil, errors.New("文章内容不能为空")
	}

	// 从上下文中获取用户ID
	userIDStr := l.ctx.Value("user_id")
	if userIDStr == nil {
		return nil, errors.New("未授权访问")
	}

	// 转换用户ID
	var userID uint
	switch v := userIDStr.(type) {
	case json.Number:
		// 处理json.Number类型
		id, err := v.Int64()
		if err != nil {
			return nil, errors.New("无效的用户ID格式")
		}
		userID = uint(id)
	case string:
		id, err := strconv.ParseUint(v, 10, 32)
		if err != nil {
			return nil, errors.New("无效的用户ID")
		}
		userID = uint(id)
	case uint:
		userID = v
	case int:
		userID = uint(v)
	case int64:
		userID = uint(v)
	case float64:
		userID = uint(v)
	default:
		return nil, errors.New("无效的用户ID类型")
	}

	// 创建文章
	post := model.Post{
		Title:   req.Title,
		Content: req.Content,
		UserID:  userID,
	}

	if err := l.svcCtx.DB.Create(&post).Error; err != nil {
		logx.Errorf("创建文章失败: %v", err)
		return nil, errors.New("服务器内部错误")
	}

	// 预加载用户信息
	if err := l.svcCtx.DB.Preload("User").First(&post, post.ID).Error; err != nil {
		logx.Errorf("查询文章失败: %v", err)
		return nil, errors.New("服务器内部错误")
	}

	return &types.PostInfo{
		Id:        int64(post.ID),
		Title:     post.Title,
		Content:   post.Content,
		UserId:    int64(post.UserID),
		Username:  post.User.Username,
		CreatedAt: post.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt: post.UpdatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}
