package handler

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/zeromicro/go-zero/rest/httpx"
	"go_zero_blog/internal/logic"
	"go_zero_blog/internal/svc"
)

func getPostHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 从URL路径中直接提取ID参数
		path := r.URL.Path
		// 路径格式: /api/v1/posts/:id
		parts := strings.Split(path, "/")
		var id string
		

		// 查找posts后面的ID
		for i, part := range parts {
			if part == "posts" && i+1 < len(parts) {
				id = parts[i+1]
				break
			}
		}
		
		// 如果没找到ID，尝试从最后一个路径段获取
		if id == "" && len(parts) > 0 {
			lastPart := parts[len(parts)-1]
			if lastPart != "" && lastPart != "posts" {
				id = lastPart
			}
		}
		

		if id == "" {
			httpx.ErrorCtx(r.Context(), w, errors.New("文章ID不能为空"))
			return
		}
		
		// 将ID参数注入到上下文中
		ctx := context.WithValue(r.Context(), "id", id)
		l := logic.NewGetPostLogic(ctx, svcCtx)
		resp, err := l.GetPost(id)
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
