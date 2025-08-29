package utils

import (
	"go_zero_blog/internal/config"
	"os"
	"path/filepath"
	"strings"

	"github.com/zeromicro/go-zero/core/logx"
)

// InitLogger 初始化日志配置
func InitLogger(c config.Config) {
	// 设置日志级别
	switch strings.ToLower(c.AppLog.Level) {
	case "debug":
		logx.SetLevel(logx.DebugLevel)
	case "info":
		logx.SetLevel(logx.InfoLevel)
	case "warn":
		logx.SetLevel(logx.ErrorLevel)
	case "error":
		logx.SetLevel(logx.ErrorLevel)
	default:
		logx.SetLevel(logx.InfoLevel)
	}

	// 设置日志模式
	if c.AppLog.Mode == "file" {
		// 确保日志目录存在
		logDir := filepath.Dir(c.AppLog.Path)
		if err := os.MkdirAll(logDir, 0755); err != nil {
			logx.Error("Failed to create log directory:", err)
			return
		}

		// 配置文件日志
		logx.MustSetup(logx.LogConf{
			ServiceName: "blog",
			Mode:        "file",
			Path:        c.AppLog.Path,
			Level:       c.AppLog.Level,
		})
	} else {
		// 控制台日志
		logx.MustSetup(logx.LogConf{
			ServiceName: "blog",
			Mode:        "console",
			Level:       c.AppLog.Level,
		})
	}
}

// LogRequest 记录请求日志
func LogRequest(method, path, userAgent, clientIP string) {
	logx.Infof("Request: %s %s - UserAgent: %s - ClientIP: %s", method, path, userAgent, clientIP)
}

// LogError 记录错误日志
func LogError(operation string, err error) {
	logx.Errorf("Error in %s: %v", operation, err)
}

// LogInfo 记录信息日志
func LogInfo(message string, args ...interface{}) {
	logx.Infof(message, args...)
}