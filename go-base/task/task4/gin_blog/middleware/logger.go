package middleware

import (
	"os"
	"path/filepath"
	"strings"

	"gin_blog/config"
	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// LoggerMiddleware 日志中间件
func LoggerMiddleware() gin.HandlerFunc {
	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		// 使用logrus记录请求日志
		logrus.WithFields(logrus.Fields{
			"status_code":  param.StatusCode,
			"latency":      param.Latency,
			"client_ip":    param.ClientIP,
			"method":       param.Method,
			"path":         param.Path,
			"user_agent":   param.Request.UserAgent(),
			"error_message": param.ErrorMessage,
		}).Info("HTTP Request")

		return ""
	})
}

// ErrorHandlerMiddleware 错误处理中间件
func ErrorHandlerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		// 处理panic错误
		if len(c.Errors) > 0 {
			err := c.Errors.Last()
			logrus.WithFields(logrus.Fields{
				"error": err.Error(),
				"path":  c.Request.URL.Path,
				"method": c.Request.Method,
			}).Error("Request Error")

			// 如果还没有响应，返回500错误
			if !c.Writer.Written() {
				c.JSON(500, gin.H{
					"code":    500,
					"message": "Internal Server Error",
				})
			}
		}
	}
}

// InitLogger 初始化日志配置
func InitLogger() {
	cfg := config.GetConfig()

	// 设置日志格式
	if cfg.Log.Format == "json" {
		logrus.SetFormatter(&logrus.JSONFormatter{
			TimestampFormat: "2006-01-02T15:04:05Z07:00",
		})
	} else {
		logrus.SetFormatter(&logrus.TextFormatter{
			FullTimestamp:   true,
			TimestampFormat: "2006-01-02 15:04:05",
		})
	}

	// 设置日志级别
	switch strings.ToLower(cfg.Log.Level) {
	case "debug":
		logrus.SetLevel(logrus.DebugLevel)
	case "info":
		logrus.SetLevel(logrus.InfoLevel)
	case "warn":
		logrus.SetLevel(logrus.WarnLevel)
	case "error":
		logrus.SetLevel(logrus.ErrorLevel)
	default:
		logrus.SetLevel(logrus.InfoLevel)
	}

	// 设置日志输出
	if cfg.Log.Output == "file" && cfg.Log.FilePath != "" {
		// 确保日志目录存在
		logDir := filepath.Dir(cfg.Log.FilePath)
		if err := os.MkdirAll(logDir, 0755); err != nil {
			logrus.Errorf("Failed to create log directory: %v", err)
		} else {
			// 打开日志文件
			logFile, err := os.OpenFile(cfg.Log.FilePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
			if err != nil {
				logrus.Errorf("Failed to open log file: %v", err)
			} else {
				logrus.SetOutput(logFile)
			}
		}
	}

	logrus.Info("Logger initialized successfully")
}