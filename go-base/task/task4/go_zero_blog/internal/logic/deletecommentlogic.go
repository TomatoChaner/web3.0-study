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

type DeleteCommentLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewDeleteCommentLogic(ctx context.Context, svcCtx *svc.ServiceContext) *DeleteCommentLogic {
	return &DeleteCommentLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *DeleteCommentLogic) DeleteComment() (resp *types.BaseResp, err error) {
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

	// 从路径参数中获取评论ID
	commentIDStr := l.ctx.Value("id")
	if commentIDStr == nil {
		return nil, errors.New("评论ID不能为空")
	}

	// 转换评论ID
	var commentID uint
	switch v := commentIDStr.(type) {
	case string:
		id, err := strconv.ParseUint(v, 10, 32)
		if err != nil {
			return nil, errors.New("无效的评论ID")
		}
		commentID = uint(id)
	case uint:
		commentID = v
	case int:
		commentID = uint(v)
	case int64:
		commentID = uint(v)
	default:
		return nil, errors.New("无效的评论ID类型")
	}

	// 查询评论是否存在并检查权限
	var comment model.Comment
	result := l.svcCtx.DB.First(&comment, commentID)
	if errors.Is(result.Error, gorm.ErrRecordNotFound) {
		return nil, errors.New("评论不存在")
	} else if result.Error != nil {
		logx.Errorf("查询评论失败: %v", result.Error)
		return nil, errors.New("服务器内部错误")
	}

	// 检查是否为评论作者
	if comment.UserID != userID {
		return nil, errors.New("无权限删除此评论")
	}

	// 删除评论
	if err := l.svcCtx.DB.Delete(&comment).Error; err != nil {
		logx.Errorf("删除评论失败: %v", err)
		return nil, errors.New("服务器内部错误")
	}

	return &types.BaseResp{
		Code:    200,
		Message: "删除成功",
	}, nil
}
