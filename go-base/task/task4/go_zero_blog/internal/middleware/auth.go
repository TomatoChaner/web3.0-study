package middleware

import (
	"context"
	"net/http"
	"strings"

	"go_zero_blog/internal/utils"
	"go_zero_blog/internal/config"

	"github.com/zeromicro/go-zero/rest/httpx"
)

// AuthMiddleware JWT认证中间件
type AuthMiddleware struct {
	JWTConfig config.JWTConfig
}

// NewAuthMiddleware 创建认证中间件
func NewAuthMiddleware(jwtConfig config.JWTConfig) *AuthMiddleware {
	return &AuthMiddleware{
		JWTConfig: jwtConfig,
	}
}

// Handle 处理JWT认证
func (m *AuthMiddleware) Handle(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 获取Authorization头
		auth := r.Header.Get("Authorization")
		if auth == "" {
			httpx.WriteJson(w, http.StatusUnauthorized, map[string]interface{}{
				"code":    401,
				"message": "缺少认证令牌",
			})
			return
		}

		// 检查Bearer前缀
		if !strings.HasPrefix(auth, "Bearer ") {
			httpx.WriteJson(w, http.StatusUnauthorized, map[string]interface{}{
				"code":    401,
				"message": "认证令牌格式错误",
			})
			return
		}

		// 提取token
		token := strings.TrimPrefix(auth, "Bearer ")
		if token == "" {
			httpx.WriteJson(w, http.StatusUnauthorized, map[string]interface{}{
				"code":    401,
				"message": "认证令牌不能为空",
			})
			return
		}

		// 验证token
		userID, username, err := utils.ValidateToken(token, m.JWTConfig)
		if err != nil {
			httpx.WriteJson(w, http.StatusUnauthorized, map[string]interface{}{
				"code":    401,
				"message": "认证令牌无效",
			})
			return
		}

		// 将用户信息添加到上下文
		ctx := context.WithValue(r.Context(), "user_id", userID)
		ctx = context.WithValue(ctx, "username", username)
		r = r.WithContext(ctx)

		next(w, r)
	}
}