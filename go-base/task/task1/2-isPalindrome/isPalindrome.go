/**
 * 回文数
 * 给你一个整数 x ，如果 x 是一个回文整数，返回 true ；否则，返回 false 。
 * 回文数是指正序（从左向右）和倒序（从右向左）读都是一样的整数。
 * 例如，121 是回文，而 123 不是。
 */

package main

import (
	"fmt"
	"strconv"
)

func isPalindrome(x int) bool {
	// 负数不是回文数
	if x < 0 {
		return false
	}
	// 转换为字符串
	s := strconv.Itoa(x)
	// 双指针判断回文
	for i, j := 0, len(s)-1; i < j; i, j = i+1, j-1 {
		if s[i] != s[j] {
			return false
		}
	}
	return true
}

// 测试用例函数
func main() {
	// 测试用例1: 121 -> true
	fmt.Println("isPalindrome(121):", isPalindrome(121))

	// 测试用例2: -121 -> false
	fmt.Println("isPalindrome(-121):", isPalindrome(-121))

	// 测试用例3: 10 -> false
	fmt.Println("isPalindrome(10):", isPalindrome(10))
}
