pragma solidity ^0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

import "./ITradingRewards.sol";


contract TradingRewards is ITradingRewards {
    using SafeMath for uint;

    /* ========== STATE VARIABLES ========== */

    uint _totalRewardsBalance;

    uint _currentPeriodID;
    mapping(uint => PeriodRecords) _periodsByID;

    struct PeriodRecords {
        uint totalRecordedFees;
        uint rewardsForPeriod;
        mapping(address => uint) recordedFeesForAccount;
        mapping(address => uint) claimedRewardsForAccount;
    }

    address _rewardsDistribution;
    IERC20 _rewardsToken;

    /* ========== CONSTRUCTOR ========== */

    constructor(address rewardsToken, address rewardsDistribution) public {
        // TODO: validation for _rewardsDistribution and _rewardsToken
        _rewardsToken = IERC20(rewardsToken);
        _rewardsDistribution = rewardsDistribution;
    }

    // TODO: ability to change rewards distribution
    // TODO: ability to change rewards token?

    /* ========== VIEWS ========== */

    function reward(address account, uint periodID) external view returns (uint) {
        return _calculateAvailableReward(account, periodID);
    }

    function rewardForPeriods(address account, uint[] periodIDs) external view returns (uint totalReward) {
        for (uint i = 0; i < periodIDs.length; i++) {
            uint periodID = periodIDs[i];

            totalReward = totalReward.add(_calculateAvailableReward(account, periodID));
        }
    }

    function _calculateAvailableReward(address account, uint periodID) internal view returns (uint availableReward) {
        PeriodRecords storage period = _periodsByID[periodID];

        uint maxReward = _calculateMaxReward(
            period.recordedFeesForAccount[account],
            period.totalRecordedFees,
            period.rewardsForPeriod
        );

        availableReward = maxReward.sub(period.claimedRewardsForAccount[account]);
    }

    function _calculateMaxReward(uint accountFees, uint totalFees, uint rewardsForPeriod) internal pure returns (uint) {
        // TODO: Use precision scalar
        uint participationRatio = accountFees.div(totalFees);

        return participationRatio.mul(rewardsForPeriod);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recordExchangeFee(uint amount, address account) external {
        PeriodRecords storage period = _periodsByID[currentPeriodID];

        period.recordedFeesForAccount = period.recordedFeesForAccount[account].add(amount);
        period.totalRecordedFees = period.totalRecordedFees.add(amount);

        emit FeeRecorded(amount, account, _currentPeriodID);
    }

    function claimReward(uint periodID) external updateReward(msg.sender) {
        _claimReward(msg.sender, periodID);
    }

    function claimRewardForPeriods(uint[] periodIDs) external {
        for (uint i = 0; i < periodIDs.length; i++) {
            uint periodID = periodIDs[i];

            _claimReward(msg.sender, periodID);
        }
    }

    function _claimReward(address account, uint periodID) internal {
        require(periodID < _currentPeriodID, "Cannot claim reward on active period.");

        uint availableReward = _calculateAvailableReward(account, periodID);

        // TODO: Send reward.

        _recordClaimedReward(account, availableReward, periodID);
    }

    function _recordClaimedReward(address account, uint amount, uint periodID) internal {
        PeriodRecords storage period = _periodsByID[periodID];

        period.claimedRewardsForAccount = period.claimedRewardsForAccount[account].sub(availableReward);

		_totalRewardsBalance = _totalRewardsBalance.sub(amount);

        emit RewardClaimed(amount, account, _currentPeriodID);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // TODO add restriction modifiers here

    function notifyRewardAmount(uint reward) external {
		_totalRewardsBalance = _totalRewardsBalance.add(reward);
		require(rewardsToken.balanceOf(address(this)) == _totalRewardsBalance, "Insufficient balance for proposed reward.");

    	_advanceToNextPeriod(reward);
    }

	function withdrawTokens(address token, uint amount) external {
		if (token == address(rewardsToken)) {
			// TODO: Consider/discuss this restriction.
			require(rewardsToken.balanceOf(address(this)) > _totalRewardsBalance, "Cannot withdraw tokens already assigned for rewards.");

			// TODO: Send tokens.
		} else {
			// TODO: Send tokens.
		}
	}

    function _advanceToNextPeriod(uint reward) internal {
        _currentPeriodID = _currentPeriodID.add(1);

        _periodsByID[currentPeriodID] = PeriodRecords({
			rewardsForPeriod: reward
        });

        emit NewPeriodStarted(_currentPeriodID, reward);
    }

    /* ========== MODIFIERS ========== */

    /* ========== EVENTS ========== */

    event FeeRecorded(uint amount, address account, uint periodID);
    event RewardClaimed(uint amount, address account, uint periodID);
    event PeriodStarted(uint periodID, uint rewards);
}
