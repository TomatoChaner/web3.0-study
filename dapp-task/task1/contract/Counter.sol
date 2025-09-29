/**
 * @title Counter
 * @dev 一个简单的计数器合约
 */
contract Counter {
    uint256 public count;

    /**
     * @dev 增加计数器的值
     */
    function increment() public {
        count += 1;
    }
}
