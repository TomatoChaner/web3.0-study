package handler

import (
	"context"
	"errors"
	"net/http"
	"strconv"

	"github.com/zeromicro/go-zero/rest/httpx"
	"go_zero_blog/internal/logic"
	"go_zero_blog/internal/svc"
)

func deletePostHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 从URL路径中提取文章ID
		idStr := r.URL.Path[len("/api/v1/posts/"):]
		if idStr == "" {
			httpx.ErrorCtx(r.Context(), w, errors.New("文章ID不能为空"))
			return
		}

		// 验证ID格式
		_, err := strconv.ParseUint(idStr, 10, 32)
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, errors.New("无效的文章ID格式"))
			return
		}

		// 将文章ID注入到上下文中
		ctx := context.WithValue(r.Context(), "id", idStr)

		l := logic.NewDeletePostLogic(ctx, svcCtx)
		resp, err := l.DeletePost()
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
