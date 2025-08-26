/*
 * 最长公共前缀
 * 编写一个函数来查找字符串数组中的最长公共前缀。
 * 如果不存在公共前缀，返回空字符串 ""。
 */
package main

import (
	"fmt"
)

/*
1. 遍历字符串数组，找到最短的字符串
2. 遍历最短字符串的每个字符，判断是否与其他字符串的对应字符相同
3. 如果不同，返回当前前缀
4. 如果相同，继续判断下一个字符
5. 最后返回最长公共前缀
*/
func longestCommonPrefix(strs []string) string {
	// 遍历字符串数组，找到最短的字符串
	shortest := strs[0]
	for i := 1; i < len(strs); i++ {
		if len(strs[i]) < len(shortest) {
			shortest = strs[i]
		}
	}
	// 遍历最短字符串的每个字符，判断是否与其他字符串的对应字符相同
	for i := 0; i < len(shortest); i++ {
		for j := 0; j < len(strs); j++ {
			if strs[j][i] != shortest[i] {
				// 如果不同，返回当前前缀
				return shortest[:i]
			}
		}
	}
	// 如果相同，继续判断下一个字符
	return shortest
}

func main() {
	// 测试用例1: ["flower","flow","flight"] -> "fl"
	fmt.Println("longestCommonPrefix(\"flower\",\"flow\",\"flight\"):", longestCommonPrefix([]string{"flower", "flow", "flight"}))
	// 测试用例2: ["dog","racecar","car"] -> ""
	fmt.Println("longestCommonPrefix(\"dog\",\"racecar\",\"car\"):", longestCommonPrefix([]string{"dog", "racecar", "car"}))
}
