/*
题目：两数之和
给定一个整数数组 nums 和一个整数目标值 target，请你在该数组中找出 和为目标值 target 的那 两个 整数，并返回它们的数组下标。
你可以假设每种输入只会对应一个答案。但是，数组中同一个元素在答案里不能重复出现。
你可以按任意顺序返回答案。

算法思路：
1. 使用哈希表存储已遍历过的元素值和对应的索引
2. 对于每个元素，计算目标值与当前元素的差值
3. 检查差值是否已存在于哈希表中
4. 如果存在，返回差值的索引和当前索引；否则将当前元素存入哈希表

时间复杂度：O(n) - 只需遍历一次数组
空间复杂度：O(n) - 哈希表存储空间
*/
package main

import (
	"fmt"
)

// twoSum 在数组中找出和为目标值的两个数的索引
// 参数: nums - 整数数组, target - 目标值
// 返回值: 两个数的索引数组
func twoSum(nums []int, target int) []int {
	// 初始化一个map，用于存储元素值和其索引
	numMap := make(map[int]int)

	// 遍历数组
	for i, num := range nums {
		// 计算目标值与当前元素的差值
		complement := target - num

		// 检查差值是否已经存在于map中
		if index, found := numMap[complement]; found {
			// 如果存在，返回差值的索引和当前索引
			return []int{index, i}
		}

		// 如果不存在，将当前元素和索引添加到map中
		numMap[num] = i
	}

	// 如果没有找到符合条件的两个数，返回空切片
	return []int{}
}

func main() {
	// 测试用例1：基本情况
	nums1 := []int{2, 7, 11, 15}
	target1 := 9
	result1 := twoSum(nums1, target1)
	fmt.Printf("输入: nums = %v, target = %d\n", nums1, target1)
	fmt.Printf("输出: %v\n", result1)
	fmt.Printf("期望: [0 1]\n\n")

	// 测试用例2：目标值在数组中间
	nums2 := []int{3, 2, 4}
	target2 := 6
	result2 := twoSum(nums2, target2)
	fmt.Printf("输入: nums = %v, target = %d\n", nums2, target2)
	fmt.Printf("输出: %v\n", result2)
	fmt.Printf("期望: [1 2]\n\n")

	// 测试用例3：相同元素
	nums3 := []int{3, 3}
	target3 := 6
	result3 := twoSum(nums3, target3)
	fmt.Printf("输入: nums = %v, target = %d\n", nums3, target3)
	fmt.Printf("输出: %v\n", result3)
	fmt.Printf("期望: [0 1]\n\n")

}
