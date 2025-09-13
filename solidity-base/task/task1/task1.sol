/**
 * 1.创建一个名为Voting的合约，包含以下功能：
 * 一个mapping来存储候选人的得票数,
 * 一个vote函数，允许用户投票给某个候选人,
 * 一个getVotes函数，返回某个候选人的得票数,
 * 一个resetVotes函数，重置所有候选人的得票数
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    // mapping来存储候选人的得票数
    mapping(string => uint256) private votes;

    // 存储所有候选人名单，用于重置功能
    string[] private candidates;

    // 记录候选人是否已存在
    mapping(string => bool) private candidateExists;

    // 事件：投票成功
    event VoteCast(string candidate, uint256 newVoteCount);

    // 事件：重置投票
    event VotesReset();

    /**
     * @dev 投票函数，允许用户投票给某个候选人
     * @param candidate 候选人名称
     */
    function vote(string memory candidate) public {
        require(bytes(candidate).length > 0, "Candidate name cannot be empty");

        // 如果候选人不存在，添加到候选人列表
        if (!candidateExists[candidate]) {
            candidates.push(candidate);
            candidateExists[candidate] = true;
        }

        // 增加候选人得票数
        votes[candidate]++;

        // 触发投票事件
        emit VoteCast(candidate, votes[candidate]);
    }

    /**
     * @dev 获取某个候选人的得票数
     * @param candidate 候选人名称
     * @return 候选人的得票数
     */
    function getVotes(string memory candidate) public view returns (uint256) {
        return votes[candidate];
    }

    /**
     * @dev 重置所有候选人的得票数
     */
    function resetVotes() public {
        // 重置所有候选人的得票数
        for (uint256 i = 0; i < candidates.length; i++) {
            votes[candidates[i]] = 0;
        }

        // 触发重置事件
        emit VotesReset();
    }

    /**
     *  反转字符串 (Reverse String),
     *  题目描述：反转一个字符串。输入 "abcde"，输出 "edcba"
     */
    function reverseString(
        string memory str
    ) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        uint256 len = strBytes.length;
        bytes memory reversedBytes = new bytes(len);

        for (uint256 i = 0; i < len; i++) {
            reversedBytes[i] = strBytes[len - 1 - i];
        }

        return string(reversedBytes);
    }

    /**
     * 用 solidity 实现整数转罗马数字
     * 题目描述：将一个整数转换为罗马数字。输入 1994，输出 "MCMXCIV"
     */
    function intToRoman(uint256 num) public pure returns (string memory) {
        // 创建数值数组，按从大到小顺序排列，包含所有可能的罗马数字组合
        // 使用贪心算法：优先使用较大的数值进行转换
        uint256[] memory values = new uint256[](13);
        values[0] = 1000;
        values[1] = 900;
        values[2] = 500;
        values[3] = 400;
        values[4] = 100;
        values[5] = 90;
        values[6] = 50;
        values[7] = 40;
        values[8] = 10;
        values[9] = 9;
        values[10] = 5;
        values[11] = 4;
        values[12] = 1;

        // 创建对应的罗马数字符号数组，与数值数组一一对应
        // 包含基本符号(I,V,X,L,C,D,M)和减法组合(IV,IX,XL,XC,CD,CM)
        string[] memory symbols = new string[](13);
        symbols[0] = "M";
        symbols[1] = "CM";
        symbols[2] = "D";
        symbols[3] = "CD";
        symbols[4] = "C";
        symbols[5] = "XC";
        symbols[6] = "L";
        symbols[7] = "XL";
        symbols[8] = "X";
        symbols[9] = "IX";
        symbols[10] = "V";
        symbols[11] = "IV";
        symbols[12] = "I";

        string memory result = ""; // 存储最终的罗马数字结果
        uint256 i = 0; // 数组索引，从最大值开始遍历

        // 贪心算法核心逻辑：从最大的罗马数字开始，尽可能多地使用当前数值
        while (num > 0 && i < values.length) {
            if (num >= values[i]) {
                // 如果当前数字大于等于当前罗马数字值，则使用该罗马数字
                num -= values[i]; // 减去对应的数值
                result = string(abi.encodePacked(result, symbols[i])); // 拼接罗马数字符号
            } else {
                // 如果当前数字小于当前罗马数字值，则移动到下一个较小的罗马数字
                i++;
            }
        }
        return result; // 返回转换后的罗马数字字符串
    }

    /**
     * 用 solidity 实现罗马数字转数整数
     * 题目描述：将一个罗马数字转换为整数。输入 "MCMXCIV"，输出 1994
     */
    function romanToInt(string memory s) public pure returns (uint256) {
        // 将字符串转换为bytes数组以便访问单个字符
        bytes memory romanBytes = bytes(s);

        uint256 result = 0; // 存储最终的整数结果
        uint256 prevValue = 0; // 前一个罗马数字的数值

        // 从字符串的末尾开始遍历，使用int类型避免溢出
        for (int256 i = int256(romanBytes.length) - 1; i >= 0; i--) {
            bytes1 currentChar = romanBytes[uint256(i)]; // 当前罗马数字字符
            uint256 currentValue = getRomanValue(currentChar); // 获取当前罗马数字的数值

            // 如果当前数值小于前一个数值，说明是减法情况，需要减去当前数值
            if (currentValue < prevValue) {
                result -= currentValue;
            } else {
                result += currentValue;
            }

            prevValue = currentValue; // 更新前一个数值为当前数值
        }

        return result; // 返回转换后的整数结果
    }

    /**
     * 根据罗马数字字符返回对应的数值
     * @param romanChar 罗马数字字符
     * @return 对应的数值
     */
    function getRomanValue(bytes1 romanChar) private pure returns (uint256) {
        if (romanChar == "I") return 1;
        if (romanChar == "V") return 5;
        if (romanChar == "X") return 10;
        if (romanChar == "L") return 50;
        if (romanChar == "C") return 100;
        if (romanChar == "D") return 500;
        if (romanChar == "M") return 1000;
        return 0; // 无效字符返回0
    }

    /**
     * 合并两个有序数组 (Merge Sorted Array)
     * 题目描述：将两个有序数组合并为一个有序数组。
     * 算法思路：使用双指针技术，同时遍历两个数组，比较元素大小后按顺序放入结果数组
     * 时间复杂度：O(m + n)，空间复杂度：O(m + n)
     * @param arr1 第一个有序数组
     * @param arr2 第二个有序数组
     * @return 合并后的有序数组
     */
    function mergeSortedArrays(
        uint256[] memory arr1,
        uint256[] memory arr2
    ) public pure returns (uint256[] memory) {
        // 获取两个数组的长度
        uint256 m = arr1.length; // 第一个数组的长度
        uint256 n = arr2.length; // 第二个数组的长度

        // 创建结果数组，长度为两个数组长度之和
        uint256[] memory mergedArray = new uint256[](m + n);

        // 初始化三个指针
        uint256 i = 0; // arr1的指针
        uint256 j = 0; // arr2的指针
        uint256 k = 0; // mergedArray的指针

        // 双指针遍历：同时遍历两个数组，比较元素大小
        while (i < m && j < n) {
            if (arr1[i] <= arr2[j]) {
                // 如果arr1当前元素小于等于arr2当前元素，选择arr1的元素
                mergedArray[k] = arr1[i];
                i++; // arr1指针向前移动
            } else {
                // 如果arr2当前元素更小，选择arr2的元素
                mergedArray[k] = arr2[j];
                j++; // arr2指针向前移动
            }
            k++; // 结果数组指针向前移动
        }

        // 处理arr1剩余元素：如果arr1还有未处理的元素，直接复制到结果数组
        while (i < m) {
            mergedArray[k] = arr1[i];
            i++;
            k++;
        }

        // 处理arr2剩余元素：如果arr2还有未处理的元素，直接复制到结果数组
        while (j < n) {
            mergedArray[k] = arr2[j];
            j++;
            k++;
        }

        // 返回合并后的有序数组
        return mergedArray;
    }

    /**
     * 二分查找 (Binary Search)
     * 题目描述：在一个有序数组中查找目标值。
     */
    function binarySearch(
        uint256[] memory arr,
        uint256 target
    ) public pure returns (int256) {
        // 初始化左右指针
        int256 left = 0;
        int256 right = int256(arr.length) - 1;

        // 二分查找循环
        while (left <= right) {
            int256 mid = left + (right - left) / 2; // 计算中间索引
            if (arr[uint256(mid)] == target) {
                return mid; // 找到目标值，返回索引
            } else if (arr[uint256(mid)] < target) {
                left = mid + 1; // 目标值在右半部分，更新左指针
            } else {
                right = mid - 1; // 目标值在左半部分，更新右指针
            }
        }

        return -1; // 未找到目标值，返回-1
    }
}
