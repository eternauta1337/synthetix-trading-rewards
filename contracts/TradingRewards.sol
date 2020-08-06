pragma solidity ^0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity-2.3.0/contracts/token/ERC20/SafeERC20.sol";

import "./ITradingRewards.sol";


contract TradingRewards is ITradingRewards {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    uint _currentPeriodID;
    mapping(uint => PeriodRecords) _periodsByID;

    struct PeriodRecords {
        uint recordedFees;
        uint totalRewards;
        uint availableRewards;
        mapping(address => uint) recordedFeesForAccount;
        mapping(address => uint) claimedRewardsForAccount;
    }

    address _owner;
    address _rewardsDistribution;

    IERC20 _rewardsToken;

    /* ========== CONSTRUCTOR ========== */

    constructor(address owner, address rewardsToken, address rewardsDistribution) public {
        // TODO: validation
        _owner = owner;
        _rewardsToken = IERC20(rewardsToken);
        _rewardsDistribution = rewardsDistribution;
    }

    // TODO: ability to change rewards distribution/token, owner

    /* ========== VIEWS ========== */

    function reward(address account, uint periodID) external view returns (uint) {
        return _calculateAvailableRewardForAccountInPeriod(account, periodID);
    }

    function rewardForPeriods(address account, uint[] periodIDs) external view returns (uint totalReward) {
        for (uint i = 0; i < periodIDs.length; i++) {
            uint periodID = periodIDs[i];

            totalReward = totalReward.add(_calculateAvailableRewardForAccountInPeriod(account, periodID));
        }
    }

    function _calculateAvailableRewardForAccountInPeriod(address account, uint periodID) internal view returns (uint availableReward) {
        PeriodRecords storage period = _periodsByID[periodID];

        if (period.availableRewards == 0) {
            return 0;
        }

        // TODO: Use precision scalar
        uint accountFees = period.recordedFeesForAccount[account];
        uint participationRatio = accountFees.div(period.totalFees);
        uint maxReward = participationRatio.mul(period.totalRewards);

        uint alreadyClaimed = period.claimedRewardsForAccount[account];
        availableReward = maxReward.sub(alreadyClaimed);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // TODO: Protect from reentrancy.

    function recordExchangeFee(uint amount, address account) external {
        PeriodRecords storage period = _periodsByID[currentPeriodID];

        period.recordedFeesForAccount = period.recordedFeesForAccount[account].add(amount);
        period.recordedFees = period.recordedFees.add(amount);

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

        uint amountToClaim = _calculateAvailableRewardForAccountInPeriod(account, periodID);

        PeriodRecords storage period = _periodsByID[periodID];
        period.claimedRewardsForAccount = period.claimedRewardsForAccount[account].sub(amountToClaim);
        period.availableRewards = period.availableRewards.sub(amountToClaim);

        rewardsToken.safeTransfer(account, amountToClaim);

        emit RewardClaimed(amount, account, _currentPeriodID);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint reward) external onlyRewardsDistribution {
        _totalRewardsBalance = _totalRewardsBalance.add(reward);
        require(rewardsToken.balanceOf(address(this)) == _totalRewardsBalance, "Insufficient balance for proposed reward.");

        uint currentBalance = rewardsToken.balanceOf(address(this));
        uint targetBalance = currentBalance.add(amount);
        uint requiredAmount = targetBalance.sub(currentBalance);
        if (requiredAmount > 0) {
            rewardsToken.safeTransferFrom(msg.sender, address(this), requiredAmount);
        }

        _currentPeriodID = _currentPeriodID.add(1);

        _periodsByID[currentPeriodID] = PeriodRecords({
            totalRewards: reward,
            availableRewards: reward
        });

        emit NewPeriodStarted(_currentPeriodID, reward);
    }

    function recoverTokens(address tokenAddress, uint amount) external onlyOwner {
        require(tokenAddress != _rewardsToken, "Reward tokens need to be withdrawn using another function.");

        IERC20(tokenAddress).safeTransfer(msg.sender);

        emit TokensRecovered(tokenAddress, amount);
    }

    function withdrawRewardTokensFromCurrentPeriod(uint amount) external onlyOwner {
        PeriodRecords storage period = _periodsByID[currentPeriodID];

        require(period.availableRewards >= amount, "Unsufficient balance for required amount.");

        period.availableRewards = period.availableRewards.sub(amount);
        period.totalRewards = period.totalRewards.sub(amount);

        _rewardsToken.safeTransfer(msg.sender);

        emit RewardsTokensWithdrawn(amount);
    }

    /* ========== MODIFIERS ========== */

    // TODO: Use modifier declared in RewardsDistributionRecipient instead.
    modifier onlyRewardsDistribution() {
        require(msg.sender == _rewardsDistribution, "Caller is not RewardsDistribution contract.");
        _;
    }

    // TODO: Use modifier declared in Owned instead.
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not owner.");
        _;
    }

    /* ========== EVENTS ========== */

    event FeeRecorded(uint amount, address account, uint periodID);
    event RewardClaimed(uint amount, address account, uint periodID);
    event NewPeriodStarted(uint periodID, uint rewards);
    event TokensRecovered(address tokenAddress, uint amount);
    event RewardsTokensWithdrawn(uint amount);
}
