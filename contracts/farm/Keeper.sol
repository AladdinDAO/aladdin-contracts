pragma solidity 0.6.12;

import "../interfaces/IVault.sol";

// A disposable keeper util contract that aggregates all vaults for simplier keeper maintaince
contract Keeper {

    /* ========== STATE VARIABLES ========== */

    address public governance;
    // only whitelisted addresses can call keeper functions
    mapping(address => bool) public isWhitelisted;
    address[] public whitelist;

    mapping(IVault => bool) public addedVaults;
    IVault[] public vaults;

    /* ========== CONSTRUCTOR ========== */

    constructor(IVault[] memory _vaults) public {
        vaults = _vaults;
        for (uint i=0; i<_vaults.length; i++) {
            addedVaults[_vaults[i]] = true;
        }
        governance = msg.sender;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function farmAll() external onlyWhitelist {
        for (uint i=0; i<vaults.length ;i++) {
            vaults[i].farm();
        }
    }

    function harvestAll() external onlyWhitelist {
        for (uint i=0; i<vaults.length ;i++) {
            vaults[i].harvest();
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    function whitelistLength() external view returns (uint256) {
        return whitelist.length;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setGov(address _governance)
        external
        onlyGov
    {
        governance = _governance;
    }

    function addVault(IVault _vault)
        external
        onlyGov
    {
        require(!addedVaults[_vault], "vault already added");
        addedVaults[_vault] = true;
        vaults.push(_vault);
    }

    function removeVault(IVault _vault)
        external
        onlyGov
    {
        require(addedVaults[_vault], "vault not added");
        addedVaults[_vault] = false;

        // find the index
        uint indexToDelete = 0;
        bool found = false;
        for (uint i = 0; i < vaults.length; i++) {
            if (vaults[i] == _vault) {
                indexToDelete = i;
                found = true;
                break;
            }
        }

        // remove element
        require(found == true, "vault not found in vaults");
        vaults[indexToDelete] = vaults[vaults.length - 1];
        vaults.pop();
    }

    function addToWhitelist(address _user)
        external
        onlyGov
    {
        require(!isWhitelisted[_user], "already in whitelist");
        isWhitelisted[_user] = true;
        whitelist.push(_user);
    }

    function removeFromWhitelist(address _user)
        external
        onlyGov
    {
        require(isWhitelisted[_user], "not in whitelist");
        isWhitelisted[_user] = false;

        // find the index
        uint indexToDelete = 0;
        bool found = false;
        for (uint i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _user) {
                indexToDelete = i;
                found = true;
                break;
            }
        }

        // remove element
        require(found == true, "user not found in whitelist");
        whitelist[indexToDelete] = whitelist[whitelist.length - 1];
        whitelist.pop();
    }

    /* ========== MODIFIER ========== */

    modifier onlyGov() {
        require(msg.sender == governance, "!gov");
        _;
    }

    modifier onlyWhitelist() {
        require(isWhitelisted[msg.sender] == true, "!whitelist");
        _;
    }
}
