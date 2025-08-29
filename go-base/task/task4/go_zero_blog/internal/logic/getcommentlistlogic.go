package logic

import (
	"context"
	"errors"

	"go_zero_blog/internal/model"
	"go_zero_blog/internal/svc"
	"go_zero_blog/internal/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type GetCommentListLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetCommentListLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetCommentListLogic {
	return &GetCommentListLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetCommentListLogic) GetCommentList(req *types.CommentListReq) (resp *types.CommentListResp, err error) {
	// 参数验证
	if req.PostId <= 0 {
		return nil, errors.New("文章ID无效")
	}
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
	if err := l.svcCtx.DB.Model(&model.Comment{}).Where("post_id = ?", req.PostId).Count(&total).Error; err != nil {
		logx.Errorf("查询评论总数失败: %v", err)
		return nil, errors.New("服务器内部错误")
	}

	// 查询评论列表
	var comments []model.Comment
	if err := l.svcCtx.DB.Preload("User").Where("post_id = ?", req.PostId).Order("created_at DESC").Limit(int(req.PageSize)).Offset(int(offset)).Find(&comments).Error; err != nil {
		logx.Errorf("查询评论列表失败: %v", err)
		return nil, errors.New("服务器内部错误")
	}

	// 转换为响应格式
	var commentList []types.CommentInfo
	for _, comment := range comments {
		commentList = append(commentList, types.CommentInfo{
			Id:        int64(comment.ID),
			Content:   comment.Content,
			PostId:    int64(comment.PostID),
			UserId:    int64(comment.UserID),
			Username:  comment.User.Username,
			CreatedAt: comment.CreatedAt.Format("2006-01-02 15:04:05"),
		})
	}

	return &types.CommentListResp{
		Total:    total,
		Page:     req.Page,
		PageSize: req.PageSize,
		List:     commentList,
	}, nil
}
