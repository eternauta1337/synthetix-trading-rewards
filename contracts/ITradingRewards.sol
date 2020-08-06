pragma solidity ^0.5.17;

interface ITradingRewards {
	// Views
	function rewards(address account, uint periodID) external view;

	function rewardsForPeriods(address account, uint[] periodIDs) external view;

	// Mutative Functions
	function recordExchangeFee(uint amount, address account) external;

	function claimReward(uint periodID) external;

	function claimRewardForPeriods(uint[] periodIDs) external;

	// Restricted Functions
	function notifyRewardAmount(uint reward) external;
}
