package middleware

import (
	"net/http"

	"github.com/zeromicro/go-zero/core/logx"
	"github.com/zeromicro/go-zero/rest/httpx"
)

// ErrorHandler 全局错误处理中间件
func ErrorHandler(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				// 记录panic错误
				logx.Errorf("Panic recovered: %v", err)
				
				// 返回统一错误响应
				httpx.WriteJson(w, http.StatusInternalServerError, map[string]interface{}{
					"code":    500,
					"message": "服务器内部错误",
					"data":    nil,
				})
			}
		}()
		
		next(w, r)
	}
}

// ErrorResponse 统一错误响应结构
type ErrorResponse struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// WriteErrorResponse 写入错误响应
func WriteErrorResponse(w http.ResponseWriter, code int, message string) {
	httpx.WriteJson(w, code, ErrorResponse{
		Code:    code,
		Message: message,
		Data:    nil,
	})
}

// WriteSuccessResponse 写入成功响应
func WriteSuccessResponse(w http.ResponseWriter, data interface{}) {
	httpx.WriteJson(w, http.StatusOK, map[string]interface{}{
		"code":    200,
		"message": "success",
		"data":    data,
	})
}