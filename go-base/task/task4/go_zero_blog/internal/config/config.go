package config

import "github.com/zeromicro/go-zero/rest"

type Config struct {
	rest.RestConf
	Database DatabaseConfig
	JWT      JWTConfig
	Auth     struct {
		AccessSecret string
		AccessExpire int64
	}
	AppLog LogConfig `json:",optional"`
}

type DatabaseConfig struct {
	Host      string
	Port      int
	Username  string
	Password  string
	DBName    string
	Charset   string
	ParseTime bool
	Loc       string
}

type JWTConfig struct {
	Secret string
	Expire int64
}

type LogConfig struct {
	Level string
	Mode  string
	Path  string
}
