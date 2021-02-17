pragma solidity 0.6.12;

import "../common/IERC20.sol";
import "../common/SafeMath.sol";
import "../common/Address.sol";
import "../common/SafeERC20.sol";

interface Strategy {
    function want() external view returns (address);
    function deposit() external;
    function withdraw(address) external;
    function withdraw(uint) external;
    function withdrawAll() external returns (uint);
    function harvest() external;
    function balanceOf() external view returns (uint);
}

interface Converter {
    function convert(address) external returns (uint);
}

interface OneSplitAudit {
    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags
    )
        external
        payable
        returns(uint256 returnAmount);

    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );
}

contract Controller {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public governance;
    address public rewards;
    address public onesplit;

    // Vault to strategy mapping
    mapping(address => address) public vaults;
    // Strategy to vault mapping
    mapping(address => address) public strategies;

    mapping(address => mapping(address => address)) public converters;

    uint public split = 500;
    uint public constant max = 10000;

    /* ========== CONSTRUCTOR ========== */

    constructor() public {
        governance = msg.sender;
        rewards = msg.sender;
        onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function balanceOf(address _vault) external view returns (uint) {
        return Strategy(strategies[_vault]).balanceOf();
    }

    function getExpectedReturn(address _strategy, address _token, uint parts) public view returns (uint expected) {
        uint _balance = IERC20(_token).balanceOf(_strategy);
        address _want = Strategy(_strategy).want();
        (expected,) = OneSplitAudit(onesplit).getExpectedReturn(_token, _want, _balance, parts, 0);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function farm(address _vault, uint _amount) public {
        address _strategy = strategies[_vault];
        address _want = Strategy(_strategy).want();
        IERC20(_want).safeTransfer(_strategy, _amount);
        Strategy(_strategy).deposit();
    }

    function harvest(address _vault) public {
        require(msg.sender == _vault, "!vault");
        Strategy(strategies[_vault]).harvest();
    }

    function withdraw(address _vault, uint _amount) public {
        require(msg.sender == _vault, "!vault");
        Strategy(strategies[_vault]).withdraw(_amount);
    }

    // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
    function harvestAndReinvest(address _strategy, address _token, uint parts) public {
        // This contract should never have value in it, but just incase since this is a public call
        uint _before = IERC20(_token).balanceOf(address(this));
        Strategy(_strategy).withdraw(_token);
        uint _after =  IERC20(_token).balanceOf(address(this));
        if (_after > _before) {
            uint _amount = _after.sub(_before);
            address _want = Strategy(_strategy).want();
            uint[] memory _distribution;
            uint _expected;
            _before = IERC20(_want).balanceOf(address(this));
            IERC20(_token).safeApprove(onesplit, 0);
            IERC20(_token).safeApprove(onesplit, _amount);
            (_expected, _distribution) = OneSplitAudit(onesplit).getExpectedReturn(_token, _want, _amount, parts, 0);
            OneSplitAudit(onesplit).swap(_token, _want, _amount, _expected, _distribution, 0);
            _after = IERC20(_want).balanceOf(address(this));
            if (_after > _before) {
                _amount = _after.sub(_before);
                uint _reward = _amount.mul(split).div(max);
                farm(_want, _amount.sub(_reward));
                IERC20(_want).safeTransfer(rewards, _reward);
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRewards(address _rewards) public {
        require(msg.sender == governance, "!governance");
        rewards = _rewards;
    }

    function setSplit(uint _split) public {
        require(msg.sender == governance, "!governance");
        split = _split;
    }

    function setOneSplit(address _onesplit) public {
        require(msg.sender == governance, "!governance");
        onesplit = _onesplit;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setConverter(address _input, address _output, address _converter) public {
        require(msg.sender == governance, "!governance");
        converters[_input][_output] = _converter;
    }

    function setStrategy(address _vault, address _strategy) public {
        require(msg.sender == governance, "!governance");

        address _current = strategies[_vault];
        if (_current != address(0)) {
           Strategy(_current).withdrawAll();
        }
        strategies[_vault] = _strategy;
        vaults[_strategy] = _vault;
    }

    function withdrawAll(address _strategy) public {
        require(msg.sender == governance, "!governance");
        // WithdrawAll sends 'want' to 'vault'
        Strategy(_strategy).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint _amount) public {
        require(msg.sender == governance, "!governance");
        IERC20(_token).safeTransfer(governance, _amount);
    }

    function inCaseStrategyTokenGetStuck(address _strategy, address _token) public {
        require(msg.sender == governance, "!governance");
        Strategy(_strategy).withdraw(_token);
        IERC20(_token).safeTransfer(governance, IERC20(_token).balanceOf(address(this)));
    }
}
