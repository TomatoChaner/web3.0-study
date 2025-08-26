/*
题目：删除有序数组中的重复项
给你一个有序数组 nums ，请你原地删除重复出现的元素，
使每个元素只出现一次，返回删除后数组的新长度。
不要使用额外的数组空间，你必须在原地修改输入数组并在使用 O(1) 额外空间的条件下完成。
可以使用双指针法，一个慢指针 i 用于记录不重复元素的位置，
一个快指针 j 用于遍历数组，当 nums[i] 与 nums[j] 不相等时，
将 nums[j] 赋值给 nums[i + 1]，并将 i 后移一位。
*/
package main

import (
	"fmt"
)

// removeDuplicates 使用双指针技术原地删除有序数组中的重复元素
// 参数: nums - 有序整数数组
// 返回值: 删除重复元素后的数组长度
func removeDuplicates(nums []int) int {
	// 边界条件：空数组直接返回0
	if len(nums) == 0 {
		return 0
	}
	
	// i指针指向当前不重复元素的位置
	i := 0
	
	// j指针遍历整个数组，寻找与nums[i]不同的元素
	for j := 1; j < len(nums); j++ {
		// 当找到不同元素时，将其移动到i+1位置
		if nums[i] != nums[j] {
			i++              // i指针前移
			nums[i] = nums[j] // 将不重复元素复制到新位置
		}
	}
	
	// 返回不重复元素的个数（i+1）
	return i + 1
}

func main() {
	// 测试用例1：普通情况
	fmt.Println("removeDuplicates([1,1,2]):", removeDuplicates([]int{1, 1, 2}))                                    // 期望输出: 2
	fmt.Println("removeDuplicates([0,0,1,1,1,2,2,3,3,4]):", removeDuplicates([]int{0, 0, 1, 1, 1, 2, 2, 3, 3, 4})) // 期望输出: 2
}
