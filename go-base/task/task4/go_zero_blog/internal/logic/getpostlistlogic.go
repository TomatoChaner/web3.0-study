package logic

import (
	"context"
	"errors"

	"go_zero_blog/internal/model"
	"go_zero_blog/internal/svc"
	"go_zero_blog/internal/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type GetPostListLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetPostListLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetPostListLogic {
	return &GetPostListLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetPostListLogic) GetPostList(req *types.PostListReq) (resp *types.PostListResp, err error) {
	// 参数验证
	if req.Page <= 0 {
		req.Page = 1
	}
	if req.PageSize <= 0 || req.PageSize > 100 {
		req.PageSize = 10
	}

	// 计算偏移量
	offset := (req.Page - 1) * req.PageSize

	// 查询总数
	var total int64
	if err := l.svcCtx.DB.Model(&model.Post{}).Count(&total).Error; err != nil {
		logx.Errorf("查询文章总数失败: %v", err)
		return nil, errors.New("服务器内部错误")
	}

	// 查询文章列表
	var posts []model.Post
	if err := l.svcCtx.DB.Preload("User").Order("created_at DESC").Limit(int(req.PageSize)).Offset(int(offset)).Find(&posts).Error; err != nil {
		logx.Errorf("查询文章列表失败: %v", err)
		return nil, errors.New("服务器内部错误")
	}

	// 转换为响应格式
	var postList []types.PostInfo
	for _, post := range posts {
		postList = append(postList, types.PostInfo{
			Id:        int64(post.ID),
			Title:     post.Title,
			Content:   post.Content,
			UserId:    int64(post.UserID),
			Username:  post.User.Username,
			CreatedAt: post.CreatedAt.Format("2006-01-02 15:04:05"),
			UpdatedAt: post.UpdatedAt.Format("2006-01-02 15:04:05"),
		})
	}

	return &types.PostListResp{
		Total:    total,
		Page:     req.Page,
		PageSize: req.PageSize,
		List:     postList,
	}, nil
}
