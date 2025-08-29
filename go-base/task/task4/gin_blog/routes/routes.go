package routes

import (
	"gin_blog/controllers"
	"gin_blog/middleware"
	"github.com/gin-gonic/gin"
)

// SetupRoutes 设置路由
func SetupRoutes() *gin.Engine {
	// 创建Gin引擎
	r := gin.New()

	// 添加中间件
	r.Use(middleware.LoggerMiddleware())
	r.Use(middleware.ErrorHandlerMiddleware())
	r.Use(gin.Recovery())

	// 创建控制器实例
	userController := controllers.NewUserController()
	postController := controllers.NewPostController()
	commentController := controllers.NewCommentController()

	// API版本分组
	api := r.Group("/api/v1")
	{
		// 用户相关路由（无需认证）
		auth := api.Group("/auth")
		{
			auth.POST("/register", userController.Register)
			auth.POST("/login", userController.Login)
		}

		// 需要认证的用户路由
		user := api.Group("/user")
		user.Use(middleware.AuthMiddleware())
		{
			user.GET("/profile", userController.GetProfile)
		}

		// 文章相关路由
		posts := api.Group("/posts")
		{
			// 公开路由（无需认证）
			posts.GET("", postController.GetPosts)           // 获取文章列表
			posts.GET("/:id", postController.GetPost)        // 获取单个文章

			// 需要认证的路由
			posts.Use(middleware.AuthMiddleware())
			posts.POST("", postController.CreatePost)        // 创建文章
			posts.PUT("/:id", postController.UpdatePost)     // 更新文章
			posts.DELETE("/:id", postController.DeletePost)  // 删除文章
		}

		// 评论相关路由
		comments := api.Group("/comments")
		{
			// 公开路由（无需认证）
			comments.GET("/post/:post_id", commentController.GetCommentsByPost) // 获取文章评论

			// 需要认证的路由
			comments.Use(middleware.AuthMiddleware())
			comments.POST("", commentController.CreateComment)           // 创建评论
			comments.DELETE("/:id", commentController.DeleteComment)     // 删除评论
		}
	}

	// 健康检查路由
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"message": "Gin Blog API is running",
		})
	})

	// 404处理
	r.NoRoute(func(c *gin.Context) {
		c.JSON(404, gin.H{
			"code":    404,
			"message": "API endpoint not found",
		})
	})

	return r
}