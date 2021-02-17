pragma solidity 0.6.12;

import "../common/IERC20.sol";
import "../common/SafeERC20.sol";
import "../common/SafeMath.sol";

interface IDAOFunding {
    function notifyRewardAmount(uint _amount) external;
}

// A token distributor that distribute tokens to addresses according to specific distribution rules
contract TokenDistributor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address public token;

    address public governance;

    address public team;
    uint public teamAllocation = 4000;

    address public dao;
    uint public daoAllocation = 4000;

    uint public constant max = 10000;

    // Remainder goes into treasury
    address public treasury;

    /* ========== CONSTRUCTOR ========== */

    constructor (
        address _token,
        address _team,
        address _dao,
        address _treasury
    ) public {
        token = _token;
        team = _team;
        dao = _dao;
        treasury = _treasury;
        governance = msg.sender;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function distribute() public {
        uint _balance = IERC20(token).balanceOf(address(this));

        uint _teamAmount = _balance.mul(teamAllocation).div(max);
        IERC20(token).safeTransfer(team, _teamAmount);

        uint _daoAmount = _balance.mul(daoAllocation).div(max);
        IERC20(token).safeTransfer(dao, _daoAmount);
        IDAOFunding(dao).notifyRewardAmount(_daoAmount);

        uint _treasuryAmount = _balance.sub(_teamAmount).sub(_daoAmount);
        IERC20(token).safeTransfer(treasury, _treasuryAmount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTeam(address _team) public {
        require(msg.sender == governance, "!governance");
        team = _team;
    }

    function setDao(address _dao) public {
        require(msg.sender == governance, "!governance");
        dao = _dao;
    }

    function setTreasury(address _treasury) public {
        require(msg.sender == governance, "!governance");
        treasury = _treasury;
    }

    function setTeamAllocation(uint _teamAllocation) public {
        require(msg.sender == governance, "!governance");
        teamAllocation = _teamAllocation;
    }

    function setDaoAllocation(uint _daoAllocation) public {
        require(msg.sender == governance, "!governance");
        daoAllocation = _daoAllocation;
    }

    function rescue(address _token) public {
        require(msg.sender == governance, "!governance");
        uint _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(governance, _balance);
    }
}
