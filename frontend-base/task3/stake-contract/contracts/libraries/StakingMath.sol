// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title StakingMath
 * @dev Library for staking-related mathematical calculations
 */
library StakingMath {
    using SafeMath for uint256;

    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant SECONDS_PER_HOUR = 3600;
    uint256 public constant SECONDS_PER_MINUTE = 60;
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant PERCENTAGE_BASE = 100;

    /**
     * @dev Calculate rewards based on amount, rate, and time
     * @param _amount Staked amount
     * @param _rate Reward rate in basis points (e.g., 100 = 1%)
     * @param _timeElapsed Time elapsed in seconds
     * @return Calculated rewards
     */
    function calculateRewards(
        uint256 _amount,
        uint256 _rate,
        uint256 _timeElapsed
    ) internal pure returns (uint256) {
        return _amount
            .mul(_rate)
            .mul(_timeElapsed)
            .div(SECONDS_PER_DAY)
            .div(BASIS_POINTS);
    }

    /**
     * @dev Calculate APY (Annual Percentage Yield)
     * @param _dailyRate Daily rate in basis points
     * @return APY in basis points
     */
    function calculateAPY(uint256 _dailyRate) internal pure returns (uint256) {
        // Simple APY calculation: dailyRate * 365
        return _dailyRate.mul(365);
    }

    /**
     * @dev Calculate compound rewards
     * @param _principal Principal amount
     * @param _rate Daily rate in basis points
     * @param _days Number of days
     * @return Compound rewards
     */
    function calculateCompoundRewards(
        uint256 _principal,
        uint256 _rate,
        uint256 _days
    ) internal pure returns (uint256) {
        if (_days == 0) return 0;
        
        uint256 totalAmount = _principal;
        uint256 dailyRateDecimal = _rate.add(BASIS_POINTS); // Add 100% (10000 basis points)
        
        // Simplified compound calculation for gas efficiency
        // In practice, you might want to use a more sophisticated approach
        for (uint256 i = 0; i < _days && i < 365; i++) {
            totalAmount = totalAmount.mul(dailyRateDecimal).div(BASIS_POINTS);
        }
        
        return totalAmount.sub(_principal);
    }

    /**
     * @dev Calculate time-based multiplier
     * @param _stakingDuration Duration of staking in seconds
     * @return Multiplier in basis points (10000 = 1x)
     */
    function calculateTimeMultiplier(uint256 _stakingDuration) internal pure returns (uint256) {
        uint256 stakingDays = _stakingDuration.div(SECONDS_PER_DAY);
        
        if (stakingDays < 7) {
            return BASIS_POINTS; // 1x multiplier
        } else if (stakingDays < 30) {
            return BASIS_POINTS.add(500); // 1.05x multiplier
        } else if (stakingDays < 90) {
            return BASIS_POINTS.add(1000); // 1.1x multiplier
        } else if (stakingDays < 180) {
            return BASIS_POINTS.add(1500); // 1.15x multiplier
        } else {
            return BASIS_POINTS.add(2000); // 1.2x multiplier
        }
    }

    /**
     * @dev Calculate penalty for early withdrawal
     * @param _amount Withdrawal amount
     * @param _stakingDuration Duration of staking in seconds
     * @param _minimumDuration Minimum staking duration in seconds
     * @return Penalty amount
     */
    function calculateEarlyWithdrawalPenalty(
        uint256 _amount,
        uint256 _stakingDuration,
        uint256 _minimumDuration
    ) internal pure returns (uint256) {
        if (_stakingDuration >= _minimumDuration) {
            return 0; // No penalty
        }
        
        // Calculate penalty percentage based on how early the withdrawal is
        uint256 penaltyRate = _minimumDuration.sub(_stakingDuration)
            .mul(1000) // 10% max penalty (1000 basis points)
            .div(_minimumDuration);
        
        return _amount.mul(penaltyRate).div(BASIS_POINTS);
    }

    /**
     * @dev Convert basis points to percentage
     * @param _basisPoints Value in basis points
     * @return Percentage value (with 2 decimal places)
     */
    function basisPointsToPercentage(uint256 _basisPoints) internal pure returns (uint256) {
        return _basisPoints.div(100);
    }

    /**
     * @dev Convert percentage to basis points
     * @param _percentage Percentage value (with 2 decimal places)
     * @return Value in basis points
     */
    function percentageToBasisPoints(uint256 _percentage) internal pure returns (uint256) {
        return _percentage.mul(100);
    }

    /**
     * @dev Calculate proportional amount
     * @param _totalAmount Total amount
     * @param _userAmount User's amount
     * @param _distributionAmount Amount to distribute
     * @return User's proportional share
     */
    function calculateProportionalAmount(
        uint256 _totalAmount,
        uint256 _userAmount,
        uint256 _distributionAmount
    ) internal pure returns (uint256) {
        if (_totalAmount == 0) return 0;
        return _distributionAmount.mul(_userAmount).div(_totalAmount);
    }

    /**
     * @dev Check if a value is within a percentage range of another value
     * @param _value Value to check
     * @param _target Target value
     * @param _tolerancePercentage Tolerance in percentage (e.g., 5 for 5%)
     * @return True if within tolerance
     */
    function isWithinTolerance(
        uint256 _value,
        uint256 _target,
        uint256 _tolerancePercentage
    ) internal pure returns (bool) {
        uint256 tolerance = _target.mul(_tolerancePercentage).div(PERCENTAGE_BASE);
        uint256 lowerBound = _target > tolerance ? _target.sub(tolerance) : 0;
        uint256 upperBound = _target.add(tolerance);
        
        return _value >= lowerBound && _value <= upperBound;
    }
}