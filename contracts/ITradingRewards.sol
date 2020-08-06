pragma solidity ^0.5.17;

interface ITradingRewards {
	// Views
	function rewards(address account, uint periodID) external view returns (uint);

	function rewardsForPeriods(address account, uint[] periodIDs) external view returns (uint);

	// Mutative Functions
	function recordExchangeFee(uint amount, address account) external;

	function claimRewards(uint periodID) external;

	function claimRewardsForPeriods(uint[] periodIDs) external;

	// Restricted Functions
	function notifyRewardAmount(uint reward) external;
}
