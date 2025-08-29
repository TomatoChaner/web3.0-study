package handler

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/zeromicro/go-zero/rest/httpx"
	"go_zero_blog/internal/logic"
	"go_zero_blog/internal/svc"
)

func deleteCommentHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 从URL路径中提取评论ID
		path := r.URL.Path
		pathSegments := strings.Split(strings.Trim(path, "/"), "/")
		
		var idStr string
		// 查找comments后面的ID
		for i, segment := range pathSegments {
			if segment == "comments" && i+1 < len(pathSegments) {
				idStr = pathSegments[i+1]
				break
			}
		}
		
		// 如果未找到，尝试从最后一个路径段获取
		if idStr == "" && len(pathSegments) > 0 {
			idStr = pathSegments[len(pathSegments)-1]
		}
		
		if idStr == "" {
			httpx.ErrorCtx(r.Context(), w, errors.New("评论ID不能为空"))
			return
		}
		
		// 验证ID格式
		_, err := strconv.ParseInt(idStr, 10, 64)
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, errors.New("无效的评论ID"))
			return
		}
		
		// 将ID参数注入到上下文中
		ctx := context.WithValue(r.Context(), "id", idStr)
		
		l := logic.NewDeleteCommentLogic(ctx, svcCtx)
		resp, err := l.DeleteComment()
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
