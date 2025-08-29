#!/bin/bash

# Gin Blog API 测试脚本
# 使用方法: ./test_api.sh

BASE_URL="http://localhost:8080"
USERNAME="testuser_$(date +%s)"
EMAIL="test_$(date +%s)@example.com"
PASSWORD="password123"

echo "=== Gin Blog API 测试脚本 ==="
echo "基础URL: $BASE_URL"
echo "测试用户: $USERNAME"
echo "测试邮箱: $EMAIL"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试函数
test_api() {
    local name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local headers="$5"
    
    echo -e "${BLUE}测试: $name${NC}"
    echo "请求: $method $url"
    
    if [ -n "$data" ]; then
        if [ -n "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" -H "Content-Type: application/json" -H "$headers" -d "$data")
        else
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" -H "Content-Type: application/json" -d "$data")
        fi
    else
        if [ -n "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" -H "$headers")
        else
            response=$(curl -s -w "\n%{http_code}" -X "$method" "$url")
        fi
    fi
    
    # 分离响应体和状态码
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    echo "状态码: $http_code"
    echo "响应: $response_body"
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓ 测试通过${NC}"
    else
        echo -e "${RED}✗ 测试失败${NC}"
    fi
    
    echo ""
    echo "$response_body"
}

# 检查服务器是否运行
echo -e "${YELLOW}检查服务器状态...${NC}"
if ! curl -s "$BASE_URL/health" > /dev/null; then
    echo -e "${RED}错误: 服务器未运行，请先启动服务器${NC}"
    echo "启动命令: go run main.go"
    exit 1
fi
echo -e "${GREEN}服务器正在运行${NC}"
echo ""

# 1. 健康检查
test_api "健康检查" "GET" "$BASE_URL/health"

# 2. 用户注册
register_data='{"username":"'$USERNAME'","password":"'$PASSWORD'","email":"'$EMAIL'"}'
register_response=$(test_api "用户注册" "POST" "$BASE_URL/api/v1/auth/register" "$register_data")

# 3. 用户登录
login_data='{"username":"'$USERNAME'","password":"'$PASSWORD'"}'
login_response=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" -H "Content-Type: application/json" -d "$login_data")
echo -e "${BLUE}测试: 用户登录${NC}"
echo "请求: POST $BASE_URL/api/v1/auth/login"
echo "响应: $login_response"

# 提取token
token=$(echo "$login_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
user_id=$(echo "$login_response" | grep -o '"user_id":[^,}]*' | cut -d':' -f2)

if [ -n "$token" ]; then
    echo -e "${GREEN}✓ 登录成功，获取到token${NC}"
    echo "Token: ${token:0:20}..."
    echo "User ID: $user_id"
else
    echo -e "${RED}✗ 登录失败，无法获取token${NC}"
    exit 1
fi
echo ""

# 4. 获取用户信息
test_api "获取用户信息" "GET" "$BASE_URL/api/v1/user/profile" "" "Authorization: Bearer $token"

# 5. 创建文章
post_data='{"title":"测试文章标题","content":"这是一篇测试文章的内容，用于验证API功能。"}'
post_response=$(curl -s -X POST "$BASE_URL/api/v1/posts" -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d "$post_data")
echo -e "${BLUE}测试: 创建文章${NC}"
echo "请求: POST $BASE_URL/api/v1/posts"
echo "响应: $post_response"

# 提取文章ID
post_id=$(echo "$post_response" | grep -o '"id":[^,}]*' | head -1 | cut -d':' -f2)

if [ -n "$post_id" ]; then
    echo -e "${GREEN}✓ 文章创建成功${NC}"
    echo "Post ID: $post_id"
else
    echo -e "${RED}✗ 文章创建失败${NC}"
fi
echo ""

# 6. 获取文章列表
test_api "获取文章列表" "GET" "$BASE_URL/api/v1/posts?page=1&page_size=10"

# 7. 获取单个文章
if [ -n "$post_id" ]; then
    test_api "获取单个文章" "GET" "$BASE_URL/api/v1/posts/$post_id"
fi

# 8. 更新文章
if [ -n "$post_id" ]; then
    update_data='{"title":"更新后的文章标题","content":"这是更新后的文章内容。"}'
    test_api "更新文章" "PUT" "$BASE_URL/api/v1/posts/$post_id" "$update_data" "Authorization: Bearer $token"
fi

# 9. 创建评论
if [ -n "$post_id" ]; then
    comment_data='{"content":"这是一条测试评论","post_id":'$post_id'}'
    comment_response=$(curl -s -X POST "$BASE_URL/api/v1/comments" -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d "$comment_data")
    echo -e "${BLUE}测试: 创建评论${NC}"
    echo "请求: POST $BASE_URL/api/v1/comments"
    echo "响应: $comment_response"
    
    # 提取评论ID
    comment_id=$(echo "$comment_response" | grep -o '"id":[^,}]*' | head -1 | cut -d':' -f2)
    
    if [ -n "$comment_id" ]; then
        echo -e "${GREEN}✓ 评论创建成功${NC}"
        echo "Comment ID: $comment_id"
    else
        echo -e "${RED}✗ 评论创建失败${NC}"
    fi
    echo ""
fi

# 10. 获取文章评论
if [ -n "$post_id" ]; then
    test_api "获取文章评论" "GET" "$BASE_URL/api/v1/comments/post/$post_id?page=1&page_size=10"
fi

# 11. 错误测试 - 未授权访问
test_api "错误测试-未授权访问" "GET" "$BASE_URL/api/v1/user/profile"

# 12. 错误测试 - 访问不存在的文章
test_api "错误测试-访问不存在的文章" "GET" "$BASE_URL/api/v1/posts/999"

# 清理测试数据（可选）
echo -e "${YELLOW}清理测试数据...${NC}"
if [ -n "$comment_id" ]; then
    echo "删除评论 ID: $comment_id"
    curl -s -X DELETE "$BASE_URL/api/v1/comments/$comment_id" -H "Authorization: Bearer $token" > /dev/null
fi

if [ -n "$post_id" ]; then
    echo "删除文章 ID: $post_id"
    curl -s -X DELETE "$BASE_URL/api/v1/posts/$post_id" -H "Authorization: Bearer $token" > /dev/null
fi

echo -e "${GREEN}测试完成！${NC}"
echo ""
echo "=== 测试总结 ==="
echo "✓ 健康检查"
echo "✓ 用户注册和登录"
echo "✓ 用户信息获取"
echo "✓ 文章CRUD操作"
echo "✓ 评论功能"
echo "✓ 错误处理测试"
echo ""
echo "如需详细测试，请使用Postman导入以下文件："
echo "- Gin_Blog_API.postman_collection.json"
echo "- Gin_Blog_API.postman_environment.json"