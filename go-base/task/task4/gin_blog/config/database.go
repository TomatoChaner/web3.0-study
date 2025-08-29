package config

import (
	"fmt"
	"log"
	"os"
	"time"

	"gin_blog/models"
	"gopkg.in/yaml.v3"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB
var config *Config

// Config 应用配置结构体
type Config struct {
	Database DatabaseConfig `yaml:"database"`
	Server   ServerConfig   `yaml:"server"`
	JWT      JWTConfig      `yaml:"jwt"`
	Log      LogConfig      `yaml:"log"`
}

// DatabaseConfig 数据库配置结构体
type DatabaseConfig struct {
	Host            string `yaml:"host"`
	Port            int    `yaml:"port"`
	User            string `yaml:"user"`
	Password        string `yaml:"password"`
	DBName          string `yaml:"dbname"`
	Charset         string `yaml:"charset"`
	MaxIdleConns    int    `yaml:"max_idle_conns"`
	MaxOpenConns    int    `yaml:"max_open_conns"`
	ConnMaxLifetime int    `yaml:"conn_max_lifetime"`
}

// ServerConfig 服务器配置结构体
type ServerConfig struct {
	Port           int `yaml:"port"`
	Mode           string `yaml:"mode"`
	ReadTimeout    int `yaml:"read_timeout"`
	WriteTimeout   int `yaml:"write_timeout"`
	MaxHeaderBytes int `yaml:"max_header_bytes"`
}

// JWTConfig JWT配置结构体
type JWTConfig struct {
	Secret       string `yaml:"secret"`
	ExpiresHours int    `yaml:"expires_hours"`
}

// LogConfig 日志配置结构体
type LogConfig struct {
	Level    string `yaml:"level"`
	Format   string `yaml:"format"`
	Output   string `yaml:"output"`
	FilePath string `yaml:"file_path"`
}

// LoadConfig 加载配置文件
func LoadConfig(configPath string) (*Config, error) {
	if configPath == "" {
		configPath = "config.yml"
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %v", err)
	}

	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %v", err)
	}

	config = &cfg
	return &cfg, nil
}

// GetConfig 获取配置实例
func GetConfig() *Config {
	if config == nil {
		// 如果配置未加载，尝试加载默认配置
		if _, err := LoadConfig(""); err != nil {
			log.Printf("Warning: Failed to load config file, using default config: %v", err)
			config = getDefaultConfig()
		}
	}
	return config
}

// getDefaultConfig 获取默认配置
func getDefaultConfig() *Config {
	return &Config{
		Database: DatabaseConfig{
			Host:            "localhost",
			Port:            3306,
			User:            "root",
			Password:        "lh123456",
			DBName:          "gin_blog",
			Charset:         "utf8mb4",
			MaxIdleConns:    10,
			MaxOpenConns:    100,
			ConnMaxLifetime: 3600,
		},
		Server: ServerConfig{
			Port:           8080,
			Mode:           "release",
			ReadTimeout:    10,
			WriteTimeout:   10,
			MaxHeaderBytes: 1048576,
		},
		JWT: JWTConfig{
			Secret:       "your-secret-key-here",
			ExpiresHours: 24,
		},
		Log: LogConfig{
			Level:    "info",
			Format:   "json",
			Output:   "stdout",
			FilePath: "logs/app.log",
		},
	}
}

// GetDefaultConfig 获取默认数据库配置
func GetDefaultConfig() *DatabaseConfig {
	cfg := GetConfig()
	return &cfg.Database
}

// InitDatabase 初始化数据库连接
func InitDatabase() {
	cfg := GetConfig()
	dbConfig := cfg.Database

	// 构建DSN
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=%s&parseTime=True&loc=Local",
		dbConfig.User,
		dbConfig.Password,
		dbConfig.Host,
		dbConfig.Port,
		dbConfig.DBName,
		dbConfig.Charset,
	)

	// 连接数据库
	var err error
	DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// 获取底层sql.DB对象进行连接池配置
	sqlDB, err := DB.DB()
	if err != nil {
		log.Fatalf("Failed to get underlying sql.DB: %v", err)
	}

	// 设置连接池参数
	sqlDB.SetMaxIdleConns(dbConfig.MaxIdleConns)
	sqlDB.SetMaxOpenConns(dbConfig.MaxOpenConns)
	sqlDB.SetConnMaxLifetime(time.Duration(dbConfig.ConnMaxLifetime) * time.Second)

	log.Println("Database connected successfully")

	// 自动迁移数据库表
	AutoMigrate()
}

// AutoMigrate 自动迁移数据库表
func AutoMigrate() {
	err := DB.AutoMigrate(
		&models.User{},
		&models.Post{},
		&models.Comment{},
	)

	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	log.Println("Database migration completed successfully")
}

// GetDB 获取数据库实例
func GetDB() *gorm.DB {
	return DB
}