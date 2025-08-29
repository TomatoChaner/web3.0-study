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

type DeletePostLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewDeletePostLogic(ctx context.Context, svcCtx *svc.ServiceContext) *DeletePostLogic {
	return &DeletePostLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *DeletePostLogic) DeletePost() (resp *types.BaseResp, err error) {
	// 从上下文中获取用户ID
	userIDValue := l.ctx.Value("user_id")
	if userIDValue == nil {
		return nil, errors.New("未授权访问")
	}

	// 转换用户ID
	var userID uint
	switch v := userIDValue.(type) {
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

	// 从路径参数中获取文章ID
	postIDStr := l.ctx.Value("id")
	if postIDStr == nil {
		return nil, errors.New("文章ID不能为空")
	}

	// 转换文章ID
	var postID uint
	switch v := postIDStr.(type) {
	case string:
		id, err := strconv.ParseUint(v, 10, 32)
		if err != nil {
			return nil, errors.New("无效的文章ID")
		}
		postID = uint(id)
	case uint:
		postID = v
	case int:
		postID = uint(v)
	case int64:
		postID = uint(v)
	default:
		return nil, errors.New("无效的文章ID类型")
	}

	// 查询文章是否存在并检查权限
	var post model.Post
	result := l.svcCtx.DB.First(&post, postID)
	if errors.Is(result.Error, gorm.ErrRecordNotFound) {
		return nil, errors.New("文章不存在")
	} else if result.Error != nil {
		logx.Errorf("查询文章失败: %v", result.Error)
		return nil, errors.New("服务器内部错误")
	}

	// 检查是否为文章作者
	if post.UserID != userID {
		return nil, errors.New("无权限删除此文章")
	}

	// 删除文章（软删除）
	if err := l.svcCtx.DB.Delete(&post).Error; err != nil {
		logx.Errorf("删除文章失败: %v", err)
		return nil, errors.New("服务器内部错误")
	}

	return &types.BaseResp{
		Code:    200,
		Message: "删除成功",
	}, nil
}
