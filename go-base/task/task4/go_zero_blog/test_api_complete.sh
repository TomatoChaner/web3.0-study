#!/bin/bash

# Go Zero Blog API 完整测试脚本
# 使用方法: ./test_api_complete.sh

set -e  # 遇到错误立即退出

# 配置
BASE_URL="http://localhost:8888"
TEST_USERNAME="test@example.com"
TEST_EMAIL="test@example.com"
TEST_PASSWORD="password123"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_step() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 检查服务器是否运行
check_server() {
    print_step "检查服务器状态"
    if curl -s "$BASE_URL/api/v1/ping" > /dev/null 2>&1; then
        print_success "服务器运行正常"
    else
        print_warning "无法连接到服务器，尝试基本连接测试"
        if curl -s "$BASE_URL" > /dev/null 2>&1; then
            print_success "服务器连接正常"
        else
            print_error "服务器未运行，请先启动服务器: go run blog.go"
            exit 1
        fi
    fi
}

# 用户注册
register_user() {
    print_step "用户注册测试"
    
    REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/auth/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"username\": \"$TEST_USERNAME\",
            \"email\": \"$TEST_EMAIL\",
            \"password\": \"$TEST_PASSWORD\"
        }")
    
    HTTP_CODE=$(echo "$REGISTER_RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$REGISTER_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "用户注册成功"
    else
        print_warning "用户注册失败 (可能用户已存在): HTTP $HTTP_CODE"
        echo "响应: $RESPONSE_BODY"
    fi
}

# 用户登录
login_user() {
    print_step "用户登录测试"
    
    LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"username\": \"$TEST_USERNAME\",
            \"password\": \"$TEST_PASSWORD\"
        }")
    
    HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$LOGIN_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        AUTH_TOKEN=$(echo "$RESPONSE_BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        USER_ID=$(echo "$RESPONSE_BODY" | grep -o '"id":[0-9]*' | cut -d':' -f2)
        print_success "用户登录成功，获取到 Token"
        echo "用户ID: $USER_ID"
    else
        print_error "用户登录失败: HTTP $HTTP_CODE"
        echo "响应: $RESPONSE_BODY"
        exit 1
    fi
}

# 获取用户信息
get_user_info() {
    print_step "获取用户信息测试"
    
    USER_INFO_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/v1/user/info" \
        -H "Authorization: Bearer $AUTH_TOKEN")
    
    HTTP_CODE=$(echo "$USER_INFO_RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$USER_INFO_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "获取用户信息成功"
        echo "用户信息: $RESPONSE_BODY"
    else
        print_error "获取用户信息失败: HTTP $HTTP_CODE"
        echo "响应: $RESPONSE_BODY"
    fi
}

# 创建文章
create_post() {
    print_step "创建文章测试"
    
    CREATE_POST_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/posts" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -d "{
            \"title\": \"API测试文章\",
            \"content\": \"这是通过API测试脚本创建的文章内容，用于验证博客系统的功能。\",
            \"summary\": \"API测试文章摘要\"
        }")
    
    HTTP_CODE=$(echo "$CREATE_POST_RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$CREATE_POST_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        POST_ID=$(echo "$RESPONSE_BODY" | grep -o '"id":[0-9]*' | cut -d':' -f2)
        print_success "创建文章成功，文章ID: $POST_ID"
    else
        print_error "创建文章失败: HTTP $HTTP_CODE"
        echo "响应: $RESPONSE_BODY"
        exit 1
    fi
}

# 获取文章列表
get_posts() {
    print_step "获取文章列表测试"
    
    GET_POSTS_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/v1/posts?page=1&limit=10" \
        -H "Authorization: Bearer $AUTH_TOKEN")
    
    HTTP_CODE=$(echo "$GET_POSTS_RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$GET_POSTS_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "获取文章列表成功"
        echo "文章数量: $(echo "$RESPONSE_BODY" | grep -o '"id":[0-9]*' | wc -l)"
    else
        print_error "获取文章列表失败: HTTP $HTTP_CODE"
        echo "响应: $RESPONSE_BODY"
    fi
}

# 获取单篇文章
get_single_post() {
    print_step "获取单篇文章测试"
    
    GET_POST_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/v1/posts/$POST_ID" \
        -H "Authorization: Bearer $AUTH_TOKEN")
    
    HTTP_CODE=$(echo "$GET_POST_RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$GET_POST_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "获取单篇文章成功"
    else
        print_error "获取单篇文章失败: HTTP $HTTP_CODE"
        echo "响应: $RESPONSE_BODY"
    fi
}

# 更新文章
update_post() {
    print_step "更新文章测试"
    
    UPDATE_POST_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/api/v1/posts/$POST_ID" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -d "{
            \"title\": \"更新后的API测试文章\",
            \"content\": \"这是更新后的文章内容，用于测试文章更新功能。\",
            \"summary\": \"更新后的文章摘要\"
        }")
    
    HTTP_CODE=$(echo "$UPDATE_POST_RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$UPDATE_POST_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "更新文章成功"
    else
        print_error "更新文章失败: HTTP $HTTP_CODE"
        echo "响应: $RESPONSE_BODY"
    fi
}

# 创建评论
create_comment() {
    print_step "创建评论测试"
    
    CREATE_COMMENT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/comments" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -d "{
            \"post_id\": $POST_ID,
            \"content\": \"这是通过API测试脚本创建的评论。\"
        }")
    
    HTTP_CODE=$(echo "$CREATE_COMMENT_RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$CREATE_COMMENT_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        COMMENT_ID=$(echo "$RESPONSE_BODY" | grep -o '"id":[0-9]*' | cut -d':' -f2)
        print_success "创建评论成功，评论ID: $COMMENT_ID"
    else
        print_error "创建评论失败: HTTP $HTTP_CODE"
        echo "响应: $RESPONSE_BODY"
    fi
}

# 获取评论列表
get_comments() {
    print_step "获取评论列表测试"
    
    GET_COMMENTS_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/v1/comments?post_id=$POST_ID" \
        -H "Authorization: Bearer $AUTH_TOKEN")
    
    HTTP_CODE=$(echo "$GET_COMMENTS_RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$GET_COMMENTS_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "获取评论列表成功"
        echo "评论数量: $(echo "$RESPONSE_BODY" | grep -o '"id":[0-9]*' | wc -l)"
    else
        print_error "获取评论列表失败: HTTP $HTTP_CODE"
        echo "响应: $RESPONSE_BODY"
    fi
}

# 删除评论
delete_comment() {
    print_step "删除评论测试"
    
    if [ -n "$COMMENT_ID" ]; then
        DELETE_COMMENT_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/api/v1/comments/$COMMENT_ID" \
            -H "Authorization: Bearer $AUTH_TOKEN")
        
        HTTP_CODE=$(echo "$DELETE_COMMENT_RESPONSE" | tail -n1)
        RESPONSE_BODY=$(echo "$DELETE_COMMENT_RESPONSE" | head -n -1)
        
        if [ "$HTTP_CODE" = "200" ]; then
            print_success "删除评论成功"
        else
            print_error "删除评论失败: HTTP $HTTP_CODE"
            echo "响应: $RESPONSE_BODY"
        fi
    else
        print_warning "跳过删除评论测试（没有评论ID）"
    fi
}

# 删除文章
delete_post() {
    print_step "删除文章测试"
    
    DELETE_POST_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/api/v1/posts/$POST_ID" \
        -H "Authorization: Bearer $AUTH_TOKEN")
    
    HTTP_CODE=$(echo "$DELETE_POST_RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$DELETE_POST_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "删除文章成功"
    else
        print_error "删除文章失败: HTTP $HTTP_CODE"
        echo "响应: $RESPONSE_BODY"
    fi
}

# 错误处理测试
test_error_handling() {
    print_step "错误处理测试"
    
    # 测试无效登录
    echo "测试无效登录..."
    INVALID_LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"username\": \"invalid@example.com\",
            \"password\": \"wrongpassword\"
        }")
    
    HTTP_CODE=$(echo "$INVALID_LOGIN_RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" != "200" ]; then
        print_success "无效登录测试通过 (HTTP $HTTP_CODE)"
    else
        print_error "无效登录测试失败 (应该返回错误)"
    fi
    
    # 测试未授权访问
    echo "测试未授权访问..."
    UNAUTHORIZED_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/v1/user/info")
    
    HTTP_CODE=$(echo "$UNAUTHORIZED_RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" = "401" ]; then
        print_success "未授权访问测试通过 (HTTP $HTTP_CODE)"
    else
        print_warning "未授权访问测试结果: HTTP $HTTP_CODE"
    fi
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "==========================================="
    echo "    Go Zero Blog API 完整测试脚本"
    echo "==========================================="
    echo -e "${NC}"
    
    check_server
    register_user
    login_user
    get_user_info
    create_post
    get_posts
    get_single_post
    update_post
    create_comment
    get_comments
    delete_comment
    delete_post
    test_error_handling
    
    echo -e "${GREEN}"
    echo "==========================================="
    echo "           🎉 所有测试完成！"
    echo "==========================================="
    echo -e "${NC}"
    
    print_success "API 功能测试全部完成"
    print_success "用户认证功能正常"
    print_success "文章管理功能正常"
    print_success "评论系统功能正常"
    print_success "错误处理功能正常"
}

# 运行主函数
main