pragma solidity ^0.5.17;

import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";


contract TradingRewards is ITradingRewards {
	using SafeMath for uint;

    /* ========== STATE VARIABLES ========== */

	uint totalRewardsBalance;

	uint currentPeriodID;
	mapping(uint => PeriodRecords) periodsByID;

	struct PeriodRecords {
		uint totalRecordedFees;
		uint rewardsForPeriod;
		mapping(address => uint) recordedFeesForAccount;
		mapping(address => uint) claimedRewardsForAccount;
	}

    /* ========== CONSTRUCTOR ========== */

	constructor() public {

	}

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
		PeriodRecords storage period = periodsByID[periodID];

		uint maxReward = _calculateMaxReward(
			period.recordedFeesForAccount[account],
			period.totalRecordedFees,
			period.rewardsForPeriod
		);

		availableReward = maxReward.sub(period.claimedRewardsForAccount[account]);
	}

	function _calculateMaxReward(uint accountFees, uint totalFees, uint rewardsForPeriod) internal view returns (uint) {
		// TODO: Use precision scalar
		uint participationRatio = accountFees.div(totalFees);

		return participationRatio.mul(rewardsForPeriod);
	}

    /* ========== MUTATIVE FUNCTIONS ========== */

	function recordExchangeFee(uint amount, address account) external {
		PeriodRecords storage period = periodsByID[currentPeriodID];

		period.recordedFeesForAccount = period.recordedFeesForAccount[account].add(amount);
		period.totalRecordedFees = period.totalRecordedFees.add(amount);

		emit FeeRecorded(amount, account, currentPeriodID);
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
		require(periodID < currentPeriodID, "Cannot claim reward on active period.");

		uint availableReward = _calculateAvailableReward(account, periodID);

		// TODO: Send reward.

		_recordClaimedReward(account, availableReward, periodID);
	}k

	function _recordClaimedReward(address account, uint amount, uint periodID) internal {
		PeriodRecords storage period = periodsByID[periodID];

		period.claimedRewardsForAccount = period.claimedRewardsForAccount[account].sub(availableReward);

		emit RewardClaimed(amount, account, currentPeriodID);
	}

    /* ========== RESTRICTED FUNCTIONS ========== */

	function notifyRewardAmount(uint reward) external {
		currentPeriodID = currentPeriodID.add(1);

		periodsByID[currentPeriodID] = PeriodRecords();
	}

    /* ========== MODIFIERS ========== */

    /* ========== EVENTS ========== */

	event FeeRecorded(uint amount, address account, uint periodID);
	event RewardClaimed(uint amount, address account, uint periodID);
}
