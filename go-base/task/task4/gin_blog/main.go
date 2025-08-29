package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"gin_blog/config"
	"gin_blog/middleware"
	"gin_blog/routes"
	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

func main() {
	// 加载配置文件
	cfg, err := config.LoadConfig("")
	if err != nil {
		log.Printf("Warning: Failed to load config file, using default config: %v", err)
		cfg = config.GetConfig()
	}

	// 初始化日志
	middleware.InitLogger()
	logrus.Info("Starting Gin Blog API Server...")

	// 初始化数据库
	config.InitDatabase()

	// 设置Gin模式
	gin.SetMode(cfg.Server.Mode)

	// 设置路由
	r := routes.SetupRoutes()

	// 创建HTTP服务器
	server := &http.Server{
		Addr:           fmt.Sprintf(":%d", cfg.Server.Port),
		Handler:        r,
		ReadTimeout:    time.Duration(cfg.Server.ReadTimeout) * time.Second,
		WriteTimeout:   time.Duration(cfg.Server.WriteTimeout) * time.Second,
		MaxHeaderBytes: cfg.Server.MaxHeaderBytes,
	}

	logrus.Infof("Server starting on port %d", cfg.Server.Port)
	logrus.Infof("API Documentation: http://localhost:%d/health", cfg.Server.Port)

	// 启动服务器
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Failed to start server: %v", err)
	}
}