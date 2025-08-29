package main

import (
	"flag"
	"fmt"

	"go_zero_blog/internal/config"
	"go_zero_blog/internal/handler"
	"go_zero_blog/internal/middleware"
	"go_zero_blog/internal/svc"
	"go_zero_blog/internal/utils"

	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/rest"
)

var configFile = flag.String("f", "etc/blog.yaml", "the config file")

func main() {
	flag.Parse()

	var c config.Config
	conf.MustLoad(*configFile, &c)

	// 初始化日志
	utils.InitLogger(c)

	server := rest.MustNewServer(c.RestConf)
	defer server.Stop()

	// 添加全局错误处理中间件
	server.Use(middleware.ErrorHandler)

	ctx := svc.NewServiceContext(c)
	handler.RegisterHandlers(server, ctx)

	fmt.Printf("Starting server at %s:%d...\n", c.Host, c.Port)
	utils.LogInfo("Blog API server starting at %s:%d", c.Host, c.Port)
	server.Start()
}
