package logic

import (
	"context"
	"errors"
	"strconv"

	"go_zero_blog/internal/model"
	"go_zero_blog/internal/svc"
	"go_zero_blog/internal/types"

	"github.com/zeromicro/go-zero/core/logx"
	"gorm.io/gorm"
)

type GetPostLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetPostLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetPostLogic {
	return &GetPostLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetPostLogic) GetPost(idStr string) (resp *types.PostInfo, err error) {
	// 验证文章ID
	if idStr == "" {
		return nil, errors.New("文章ID不能为空")
	}

	// 转换文章ID
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		return nil, errors.New("无效的文章ID")
	}
	postID := uint(id)

	// 查询文章
	var post model.Post
	result := l.svcCtx.DB.Preload("User").First(&post, postID)
	if errors.Is(result.Error, gorm.ErrRecordNotFound) {
		return nil, errors.New("文章不存在")
	} else if result.Error != nil {
		logx.Errorf("查询文章失败: %v", result.Error)
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
