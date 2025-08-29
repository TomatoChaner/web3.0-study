#!/bin/bash

# Go-Zero Blog API 测试脚本
# 使用方法: ./test_api.sh

BASE_URL="http://localhost:8888"
TOKEN=""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# 检查服务是否运行
check_service() {
    print_header "检查服务状态"
    if curl -s "$BASE_URL/ping" > /dev/null 2>&1; then
        print_success "服务正在运行"
    else
        print_error "服务未运行，请先启动服务"
        exit 1
    fi
}

# 用户注册
test_register() {
    print_header "测试用户注册"
    
    response=$(curl -s -X POST "$BASE_URL/api/v1/auth/register" \
        -H "Content-Type: application/json" \
        -d '{
            "username": "testuser",
            "email": "test@example.com",
            "password": "password123"
        }')
    
    if echo "$response" | grep -q '"code":200'; then
        print_success "用户注册成功"
        echo "Response: $response"
    else
        print_info "用户可能已存在或注册失败"
        echo "Response: $response"
    fi
}

# 用户登录
test_login() {
    print_header "测试用户登录"
    
    response=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d '{
            "username": "testuser",
            "password": "password123"
        }')
    
    if echo "$response" | grep -q '"token"'; then
        print_success "用户登录成功"
        TOKEN=$(echo "$response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        print_info "Token: $TOKEN"
    else
        print_error "用户登录失败"
        echo "Response: $response"
        exit 1
    fi
}

# 获取用户信息
test_user_info() {
    print_header "测试获取用户信息"
    
    if [ -z "$TOKEN" ]; then
        print_error "Token 为空，请先登录"
        return 1
    fi
    
    response=$(curl -s -X GET "$BASE_URL/api/v1/user/info" \
        -H "Authorization: Bearer $TOKEN")
    
    if echo "$response" | grep -q '"code":200'; then
        print_success "获取用户信息成功"
        echo "Response: $response"
    else
        print_error "获取用户信息失败"
        echo "Response: $response"
    fi
}

# 创建文章
test_create_post() {
    print_header "测试创建文章"
    
    if [ -z "$TOKEN" ]; then
        print_error "Token 为空，请先登录"
        return 1
    fi
    
    response=$(curl -s -X POST "$BASE_URL/api/v1/posts" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "测试文章标题",
            "content": "这是一篇测试文章的内容，用于验证API功能是否正常工作。"
        }')
    
    if echo "$response" | grep -q '"code":200'; then
        print_success "创建文章成功"
        POST_ID=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
        print_info "文章ID: $POST_ID"
        echo "Response: $response"
    else
        print_error "创建文章失败"
        echo "Response: $response"
    fi
}

# 获取文章列表
test_get_posts() {
    print_header "测试获取文章列表"
    
    response=$(curl -s -X GET "$BASE_URL/api/v1/posts?page=1&pageSize=10")
    
    if echo "$response" | grep -q '"code":200'; then
        print_success "获取文章列表成功"
        echo "Response: $response"
    else
        print_error "获取文章列表失败"
        echo "Response: $response"
    fi
}

# 获取文章详情
test_get_post() {
    print_header "测试获取文章详情"
    
    if [ -z "$POST_ID" ]; then
        POST_ID=1
        print_info "使用默认文章ID: $POST_ID"
    fi
    
    response=$(curl -s -X GET "$BASE_URL/api/v1/posts/$POST_ID")
    
    if echo "$response" | grep -q '"code":200'; then
        print_success "获取文章详情成功"
        echo "Response: $response"
    else
        print_error "获取文章详情失败"
        echo "Response: $response"
    fi
}

# 创建评论
test_create_comment() {
    print_header "测试创建评论"
    
    if [ -z "$TOKEN" ]; then
        print_error "Token 为空，请先登录"
        return 1
    fi
    
    if [ -z "$POST_ID" ]; then
        POST_ID=1
        print_info "使用默认文章ID: $POST_ID"
    fi
    
    response=$(curl -s -X POST "$BASE_URL/api/v1/comments" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"postId\": $POST_ID,
            \"content\": \"这是一条测试评论，用于验证评论功能。\"
        }")
    
    if echo "$response" | grep -q '"code":200'; then
        print_success "创建评论成功"
        echo "Response: $response"
    else
        print_error "创建评论失败"
        echo "Response: $response"
    fi
}

# 获取评论列表
test_get_comments() {
    print_header "测试获取评论列表"
    
    if [ -z "$POST_ID" ]; then
        POST_ID=1
        print_info "使用默认文章ID: $POST_ID"
    fi
    
    response=$(curl -s -X GET "$BASE_URL/api/v1/comments?postId=$POST_ID&page=1&pageSize=10")
    
    if echo "$response" | grep -q '"code":200'; then
        print_success "获取评论列表成功"
        echo "Response: $response"
    else
        print_error "获取评论列表失败"
        echo "Response: $response"
    fi
}

# 主函数
main() {
    echo -e "${BLUE}Go-Zero Blog API 测试脚本${NC}"
    echo "=============================="
    
    check_service
    
    echo
    test_register
    
    echo
    test_login
    
    echo
    test_user_info
    
    echo
    test_create_post
    
    echo
    test_get_posts
    
    echo
    test_get_post
    
    echo
    test_create_comment
    
    echo
    test_get_comments
    
    echo
    print_header "测试完成"
    print_success "所有API测试已完成"
}

# 运行主函数
main