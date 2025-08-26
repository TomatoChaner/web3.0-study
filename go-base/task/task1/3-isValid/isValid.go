/**
 * 有效的括号
 * 给定一个只包括 '('，')'，'{'，'}'，'['，']' 的字符串 s ，判断字符串是否有效。
 * 有效字符串需满足：
 * 左括号必须用相同类型的右括号闭合。
 * 左括号必须以正确的顺序闭合。
 * 每个右括号都有一个对应的相同类型的左括号。
 */

package main

import (
	"fmt"
)

/*
1. 遍历字符串，遇到左括号就入栈，遇到右括号就出栈
2. 出栈时，判断是否与当前右括号匹配
3. 最后判断栈是否为空
*/
func isValid(s string) bool {
	// 栈：创建切片
	stack := make([]byte, 0)
	// 遍历字符串
	for i := 0; i < len(s); i++ {
		// 遇到左括号就入栈
		if s[i] == '(' || s[i] == '[' || s[i] == '{' {
			stack = append(stack, s[i])
		} else {
			// 遇到右括号就出栈
			if len(stack) == 0 {
				return false
			}
			// 出栈
			c := stack[len(stack)-1]
			stack = stack[:len(stack)-1]
			// 判断是否匹配
			if (s[i] == ')' && c != '(') || (s[i] == ']' && c != '[') || (s[i] == '}' && c != '{') {
				return false
			}
		}
	}
	// 最后判断栈是否为空
	return len(stack) == 0
}

func main() {
	// 测试用例1: "()" -> true
	fmt.Println("isValid(\"()\"):", isValid("()"))

	// 测试用例2: "()[]{}"	-> true
	fmt.Println("isValid(\"()[]{}\"):", isValid("()[]{}"))

	// 测试用例3: "(]" -> false
	fmt.Println("isValid(\"(]\"):", isValid("(]"))
}
