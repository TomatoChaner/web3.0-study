package logic

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"strings"

	"go_zero_blog/internal/model"
	"go_zero_blog/internal/svc"
	"go_zero_blog/internal/types"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type CreateCommentLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewCreateCommentLogic(ctx context.Context, svcCtx *svc.ServiceContext) *CreateCommentLogic {
	return &CreateCommentLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *CreateCommentLogic) CreateComment(req *types.CreateCommentReq) (resp *types.CommentInfo, err error) {
	// 参数验证
	if strings.TrimSpace(req.Content) == "" {
		return nil, errors.New("评论内容不能为空")
	}
	if req.PostId <= 0 {
		return nil, errors.New("文章ID无效")
	}

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

	// 检查文章是否存在
	var post model.Post
	result := l.svcCtx.DB.First(&post, req.PostId)
	if errors.Is(result.Error, gorm.ErrRecordNotFound) {
		return nil, errors.New("文章不存在")
	} else if result.Error != nil {
		logx.Errorf("查询文章失败: %v", result.Error)
		return nil, errors.New("服务器内部错误")
	}

	// 创建评论
	comment := model.Comment{
		Content: strings.TrimSpace(req.Content),
		PostID:  uint(req.PostId),
		UserID:  userID,
	}

	if err := l.svcCtx.DB.Create(&comment).Error; err != nil {
		logx.Errorf("创建评论失败: %v", err)
		return nil, errors.New("服务器内部错误")
	}

	// 预加载用户信息
	if err := l.svcCtx.DB.Preload("User").First(&comment, comment.ID).Error; err != nil {
		logx.Errorf("查询评论详情失败: %v", err)
		return nil, errors.New("服务器内部错误")
	}

	return &types.CommentInfo{
		Id:        int64(comment.ID),
		Content:   comment.Content,
		PostId:    int64(comment.PostID),
		UserId:    int64(comment.UserID),
		Username:  comment.User.Username,
		CreatedAt: comment.CreatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}
