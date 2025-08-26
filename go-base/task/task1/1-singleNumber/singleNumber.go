/*
 * 136. 只出现一次的数字：给定一个非空整数数组，除了某个元素只出现一次以外，
 * 其余每个元素均出现两次。找出那个只出现了一次的元素。
 * 可以使用 for 循环遍历数组，结合 if 条件判断和 map 数据结构来解决，
 * 例如通过 map 记录每个元素出现的次数，然后再遍历 map 找到出现次数为1的元素。
 */
/*
 * 时间复杂度：O(n)，其中 n 是数组的长度。
 * 空间复杂度：O(n)，其中 n 是数组的长度。
 */
package main

import (
	"fmt"
)

// singleNumber 找出数组中只出现一次的数字
// 使用哈希表统计每个数字的出现次数，然后找出出现次数为1的数字
// 参数: nums - 整数数组，其中除了一个数字只出现一次外，其余数字都出现两次
// 返回: 只出现一次的数字
func singleNumber(nums []int) int {
	// 创建哈希表用于统计每个数字的出现次数
	numMap := make(map[int]int)

	// 遍历数组，统计每个数字的出现次数
	for _, num := range nums {
		numMap[num]++
	}

	// 遍历哈希表，找出出现次数为1的数字
	for num, count := range numMap {
		if count == 1 {
			return num
		}
	}

	// 如果没有找到，返回0（理论上不会执行到这里）
	return 0
}

// main 主函数，测试所有算法函数
func main() {
	fmt.Println("=== 测试 singleNumber 函数 ===")
	// 测试用例1: [2, 2, 1] -> 1
	fmt.Println("singleNumber([2, 2, 1]):", singleNumber([]int{2, 2, 1}))

	// 测试用例2: [4, 1, 2, 1, 2] -> 4
	fmt.Println("singleNumber([4, 1, 2, 1, 2]):", singleNumber([]int{4, 1, 2, 1, 2}))

	// 测试用例3: [1] -> 1
	fmt.Println("singleNumber([1]):", singleNumber([]int{1}))
}
