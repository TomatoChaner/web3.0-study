package svc

import (
	"log"

	"go_zero_blog/internal/config"
	"go_zero_blog/internal/model"
	"gorm.io/gorm"
)

type ServiceContext struct {
	Config config.Config
	DB     *gorm.DB
}

func NewServiceContext(c config.Config) *ServiceContext {
	// 初始化数据库
	if err := model.InitDatabase(c.Database); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	return &ServiceContext{
		Config: c,
		DB:     model.GetDB(),
	}
}
