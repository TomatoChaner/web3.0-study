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
	"go_zero_blog/internal/types"
)

func updatePostHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 从URL路径中提取ID参数
		path := r.URL.Path
		parts := strings.Split(path, "/")
		var idStr string
		
		// 查找posts后面的ID
		for i, part := range parts {
			if part == "posts" && i+1 < len(parts) {
				idStr = parts[i+1]
				break
			}
		}
		
		// 如果没找到ID，尝试从最后一个路径段获取
		if idStr == "" && len(parts) > 0 {
			lastPart := parts[len(parts)-1]
			if lastPart != "" && lastPart != "posts" {
				idStr = lastPart
			}
		}
		
		if idStr == "" {
			httpx.ErrorCtx(r.Context(), w, errors.New("文章ID不能为空"))
			return
		}
		
		// 验证ID格式
		_, err := strconv.ParseInt(idStr, 10, 64)
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, errors.New("无效的文章ID"))
			return
		}

		var req types.UpdatePostReq
		if err := httpx.Parse(r, &req); err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
			return
		}
		
		// 将ID参数注入到上下文中
		ctx := context.WithValue(r.Context(), "id", idStr)
		l := logic.NewUpdatePostLogic(ctx, svcCtx)
		resp, err := l.UpdatePost(&req)
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
