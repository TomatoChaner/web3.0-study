/*
题目：合并区间
以数组 intervals 表示若干个区间的集合，
其中单个区间为 intervals[i] = [starti, endi] 。请你合并所有重叠的区间，
并返回一个不重叠的区间数组，该数组需恰好覆盖输入中的所有区间。

算法思路：
1. 先对区间数组按照区间的起始位置进行排序
2. 使用一个切片来存储合并后的区间
3. 遍历排序后的区间数组，将当前区间与切片中最后一个区间进行比较
4. 如果有重叠，则合并区间；如果没有重叠，则将当前区间添加到切片中

时间复杂度：O(n log n) - 主要是排序的时间复杂度
空间复杂度：O(n) - 存储结果的空间
*/
package main

import (
	"fmt"
	"sort"
)

// merge 合并重叠的区间
// 参数: intervals - 区间数组，每个区间为[start, end]
// 返回值: 合并后的不重叠区间数组
func merge(intervals [][]int) [][]int {
	// 边界条件：空数组或只有一个区间
	if len(intervals) <= 1 {
		return intervals
	}

	// 先对区间数组按照区间的起始位置进行排序
	sort.Slice(intervals, func(i, j int) bool {
		return intervals[i][0] < intervals[j][0]
	})

	// 初始化结果切片，将第一个区间加入
	result := [][]int{intervals[0]}

	// 遍历剩余区间
	for i := 1; i < len(intervals); i++ {
		current := intervals[i]
		last := result[len(result)-1]

		// 如果当前区间与最后一个区间重叠，则合并
		if current[0] <= last[1] {
			// 更新最后一个区间的结束位置
			if current[1] > last[1] {
				result[len(result)-1][1] = current[1]
			}
		} else {
			// 没有重叠，直接添加当前区间
			result = append(result, current)
		}
	}

	return result
}

func main() {
	// 测试用例1：有重叠的区间
	test1 := [][]int{{1, 3}, {2, 6}, {8, 10}, {15, 18}}
	result1 := merge(test1)
	fmt.Printf("输入: %v\n", test1)
	fmt.Printf("输出: %v\n", result1)
	fmt.Printf("期望: [[1 6] [8 10] [15 18]]\n\n")

	// 测试用例2：相邻区间
	test2 := [][]int{{1, 4}, {4, 5}}
	result2 := merge(test2)
	fmt.Printf("输入: %v\n", test2)
	fmt.Printf("输出: %v\n", result2)
	fmt.Printf("期望: [[1 5]]\n\n")

}
