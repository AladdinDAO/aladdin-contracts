// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IALD.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/ITreasury.sol";

import "./libraries/LogExpMath.sol";

contract Treasury is Ownable, ITreasury {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Deposit(address indexed token, uint256 amount, uint256 value);
  event Withdrawal(address indexed token, uint256 amount);
  event ReservesManaged(address indexed token, address indexed manager, uint256 amount);
  event ReservesUpdated(ReserveType indexed _type, uint256 totalReserves);
  event RewardsMinted(address indexed caller, address indexed recipient, uint256 amount);

  event UpdateReserveToken(address indexed token, bool isAdd);
  event UpdateLiquidityToken(address indexed token, bool isAdd);
  event UpdateReserveDepositor(address indexed depositor, bool isAdd);
  event UpdateReserveManager(address indexed manager, bool isAdd);
  event UpdateRewardManager(address indexed manager, bool isAdd);
  event UpdatePolSpender(address indexed spender, bool isAdd);

  event UpdateDiscount(address indexed token, uint256 discount);
  event UpdatePriceOracle(address indexed token, address oracle);
  event UpdatePolPercentage(address indexed token, uint256 percentage);
  event UpdateContributorPercentage(uint256 percentage);
  event UpdateLiabilityRatio(uint256 liabilityRatio);

  uint256 private constant PRECISION = 1e18;

  // The address of governor.
  address public governor;

  // The address of ALD token
  address public immutable ald;
  // The address of ALD DAO
  address public immutable aldDAO;

  // A list of reserve tokens. Push only, beware false-positives.
  address[] public reserveTokens;
  // Record whether an address is reserve token or not.
  mapping(address => bool) public isReserveToken;

  // A list of liquidity tokens. Push only, beware false-positives.
  address[] public liquidityTokens;
  // Record whether an address is liquidity token or not.
  mapping(address => bool) public isLiquidityToken;

  // A list of reserve depositors. Push only, beware false-positives.
  address[] public reserveDepositors;
  // Record whether an address is reserve depositor or not.
  mapping(address => bool) public isReserveDepositor;

  // Mapping from token address to price oracle address.
  mapping(address => address) public priceOracle;

  // A list of reserve managers. Push only, beware false-positives.
  address[] public reserveManagers;
  // Record whether an address is reserve manager or not.
  mapping(address => bool) public isReserveManager;

  // A list of reward managers. Push only, beware false-positives.
  address[] public rewardManagers;
  // Record whether an address is reward manager or not.
  mapping(address => bool) public isRewardManager;

  // Mapping from token address to discount factor. Multiplied by 1e18
  mapping(address => uint256) public discount;

  // A list of pol spenders. Push only, beware false-positives.
  address[] public polSpenders;
  // Record whether an address is pol spender or not.
  mapping(address => bool) public isPolSpender;

  // Mapping from token address to reserve amount belong to POL.
  mapping(address => uint256) public polReserves;
  // Mapping from token address to percentage of profit to POL. Multiplied by 1e18
  mapping(address => uint256) public percentagePOL;

  // The percentage of ALD to contributors. Multiplied by 1e18
  uint256 public percentageContributor;

  // The liability ratio used to calcalate ald price. Multiplied by 1e18
  uint256 public liabilityRatio;

  // The USD value of all reserves from main asset. Multiplied by 1e18
  uint256 public totalReserveUnderlying;
  // The USD value of all reserves from vault reward. Multiplied by 1e18
  uint256 public totalReserveVaultReward;
  // The USD value of all reserves from liquidity token. Multiplied by 1e18
  uint256 public totalReserveLiquidityToken;

  modifier onlyGovernor() {
    require(msg.sender == governor || msg.sender == owner(), "Treasury: only governor");
    _;
  }

  /// @param _ald The address of ALD token
  /// @param _aldDAO The address of ALD DAO
  constructor(address _ald, address _aldDAO) {
    require(_ald != address(0), "Treasury: zero ald address");
    require(_aldDAO != address(0), "Treasury: zero aldDAO address");

    ald = _ald;
    aldDAO = _aldDAO;

    percentageContributor = 5e16; // 5%
    liabilityRatio = 1e17; // 0.1
  }

  /********************************** View Functions **********************************/

  /// @dev return the ALD bond price. mutipliled by 1e18
  function aldBondPrice() public view returns (uint256) {
    uint256 _totalReserve = totalReserveUnderlying.add(totalReserveVaultReward).add(totalReserveLiquidityToken);
    uint256 _aldSupply = IERC20(ald).totalSupply();
    return _totalReserve.mul(1e36).div(_aldSupply).div(liabilityRatio);
  }

  /// @dev return the amount of bond ALD given token and usd value, without discount.
  /// @param _value The usd of token.
  function bondOfWithoutDiscount(uint256 _value) public view returns (uint256) {
    uint256 _aldSupply = IERC20(ald).totalSupply();
    uint256 _totalReserve = totalReserveUnderlying.add(totalReserveVaultReward).add(totalReserveLiquidityToken);

    uint256 x = _totalReserve.add(_value).mul(PRECISION).div(_totalReserve);
    uint256 bond = LogExpMath.pow(x, liabilityRatio).sub(PRECISION).mul(_aldSupply).div(PRECISION);
    return bond;
  }

  /// @dev return the usd value given token and amount.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function valueOf(address _token, uint256 _amount) public view override returns (uint256) {
    return IPriceOracle(priceOracle[_token]).value(_token, _amount);
  }

  /// @dev return the amount of bond ALD given token and usd value.
  /// @param _token The address of token.
  /// @param _value The usd of token.
  function bondOf(address _token, uint256 _value) public view override returns (uint256) {
    return bondOfWithoutDiscount(_value).mul(discount[_token]).div(PRECISION);
  }

  /********************************** Mutated Functions **********************************/

  /// @dev deposit token to bond ALD.
  /// @param _type The type of deposited token.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function deposit(
    ReserveType _type,
    address _token,
    uint256 _amount
  ) external override returns (uint256) {
    require(isReserveToken[_token] || isLiquidityToken[_token], "Treasury: not accepted");
    require(isReserveDepositor[msg.sender], "Treasury: not approved depositor");

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    uint256 _value = valueOf(_token, _amount);
    uint256 _bond;

    if (_type != ReserveType.NULL) {
      // a portion of token should used as POL
      uint256 _percentagePOL = percentagePOL[_token];
      if (_percentagePOL > 0) {
        polReserves[_token] = polReserves[_token].add(_amount.mul(_percentagePOL).div(PRECISION));
      }

      // mint bond ald to sender
      _bond = bondOf(_token, _value);
      IALD(ald).mint(msg.sender, _bond);

      // mint extra ALD to ald DAO
      uint256 _percentageContributor = percentageContributor;
      if (percentageContributor > 0) {
        IALD(ald).mint(aldDAO, _bond.mul(_percentageContributor).div(PRECISION - _percentageContributor));
      }

      // update reserves
      if (_type == ReserveType.LIQUIDITY_TOKEN) {
        totalReserveLiquidityToken = totalReserveLiquidityToken.add(_value);
        emit ReservesUpdated(_type, totalReserveLiquidityToken);
      } else if (_type == ReserveType.UNDERLYING) {
        totalReserveUnderlying = totalReserveUnderlying.add(_value);
        emit ReservesUpdated(_type, totalReserveUnderlying);
      } else if (_type == ReserveType.VAULT_REWARD) {
        totalReserveVaultReward = totalReserveVaultReward.add(_value);
        emit ReservesUpdated(_type, totalReserveVaultReward);
      } else {
        revert("Treasury: invalid reserve type");
      }
    }

    emit Deposit(_token, _amount, _value);

    return _bond;
  }

  /// @dev withdraw token from POL.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function withdraw(address _token, uint256 _amount) external override {
    require(isReserveToken[_token], "Treasury: not accepted");
    require(isPolSpender[msg.sender], "Treasury: not approved spender");
    require(_amount <= polReserves[_token], "Treasury: exceed pol reserve");

    polReserves[_token] = polReserves[_token] - _amount;
    IERC20(_token).safeTransfer(msg.sender, _amount);

    emit Withdrawal(_token, _amount);
  }

  /// @dev manage token to earn passive yield.
  /// @param _token The address of token.
  /// @param _amount The amount of token.
  function manage(address _token, uint256 _amount) external override {
    require(isReserveToken[_token] || isLiquidityToken[_token], "Treasury: not accepted");
    require(isReserveManager[msg.sender], "Treasury: not approved manager");

    IERC20(_token).safeTransfer(msg.sender, _amount);
    emit ReservesManaged(_token, msg.sender, _amount);
  }

  /// @dev mint ALD reward.
  /// @param _recipient The address of to receive ALD token.
  /// @param _amount The amount of token.
  function mintRewards(address _recipient, uint256 _amount) external override {
    require(isRewardManager[msg.sender], "Treasury: not approved manager");

    IALD(ald).mint(_recipient, _amount);

    emit RewardsMinted(msg.sender, _recipient, _amount);
  }

  /********************************** Restricted Functions **********************************/

  function updateGovernor(address _governor) external onlyOwner {
    governor = _governor;
  }

  /// @dev update reserve token
  /// @param _token The address of token.
  /// @param _isAdd Whether it is add or remove token.
  function updateReserveToken(address _token, bool _isAdd) external onlyOwner {
    _addOrRemoveAddress(reserveTokens, isReserveToken, _token, _isAdd);

    emit UpdateReserveToken(_token, _isAdd);
  }

  /// @dev update liquidity token
  /// @param _token The address of token.
  /// @param _isAdd Whether it is add or remove token.
  function updateLiquidityToken(address _token, bool _isAdd) external onlyOwner {
    _addOrRemoveAddress(liquidityTokens, isLiquidityToken, _token, _isAdd);

    emit UpdateLiquidityToken(_token, _isAdd);
  }

  /// @dev update reserve depositor
  /// @param _depositor The address of depositor.
  /// @param _isAdd Whether it is add or remove token.
  function updateReserveDepositor(address _depositor, bool _isAdd) external onlyOwner {
    _addOrRemoveAddress(reserveDepositors, isReserveDepositor, _depositor, _isAdd);

    emit UpdateReserveDepositor(_depositor, _isAdd);
  }

  /// @dev update price oracle for token.
  /// @param _token The address of token.
  /// @param _oracle The address of price oracle.
  function updatePriceOracle(address _token, address _oracle) external onlyOwner {
    require(_oracle != address(0), "Treasury: zero address");
    priceOracle[_token] = _oracle;

    emit UpdatePriceOracle(_token, _oracle);
  }

  /// @dev update reserve manager.
  /// @param _manager The address of manager.
  /// @param _isAdd Whether it is add or remove token.
  function updateReserveManager(address _manager, bool _isAdd) external onlyOwner {
    _addOrRemoveAddress(reserveManagers, isReserveManager, _manager, _isAdd);

    emit UpdateReserveManager(_manager, _isAdd);
  }

  /// @dev update reward manager.
  /// @param _manager The address of manager.
  /// @param _isAdd Whether it is add or remove token.
  function updateRewardManager(address _manager, bool _isAdd) external onlyOwner {
    _addOrRemoveAddress(rewardManagers, isRewardManager, _manager, _isAdd);

    emit UpdateRewardManager(_manager, _isAdd);
  }

  /// @dev update discount factor for token.
  /// @param _token The address of token.
  /// @param _discount The discount factor. multipled by 1e18
  function updateDiscount(address _token, uint256 _discount) external onlyGovernor {
    discount[_token] = _discount;

    emit UpdateDiscount(_token, _discount);
  }

  /// @dev update POL spender.
  /// @param _spender The address of spender.
  /// @param _isAdd Whether it is add or remove token.
  function updatePolSpenders(address _spender, bool _isAdd) external onlyOwner {
    _addOrRemoveAddress(polSpenders, isPolSpender, _spender, _isAdd);

    emit UpdatePolSpender(_spender, _isAdd);
  }

  /// @dev update POL percentage for token.
  /// @param _token The address of token.
  /// @param _percentage The POL percentage. multipled by 1e18
  function updatePercentagePOL(address _token, uint256 _percentage) external onlyOwner {
    require(_percentage <= PRECISION, "Treasury: percentage too large");

    percentagePOL[_token] = _percentage;

    emit UpdatePolPercentage(_token, _percentage);
  }

  /// @dev update contributor percentage.
  /// @param _percentage The contributor percentage. multipled by 1e18
  function updatePercentageContributor(uint256 _percentage) external onlyOwner {
    require(_percentage <= PRECISION, "Treasury: percentage too large");

    percentageContributor = _percentage;

    emit UpdateContributorPercentage(_percentage);
  }

  /// @dev update protocol liability ratio
  /// @param _liabilityRatio The liability ratio. multipled by 1e18
  function updateLiabilityRatio(uint256 _liabilityRatio) external onlyOwner {
    liabilityRatio = _liabilityRatio;

    emit UpdateLiabilityRatio(_liabilityRatio);
  }

  /// @dev update protocol reserves
  /// @param _totalReserveUnderlying The underlying reserve.
  /// @param _totalReserveVaultReward The vault reward reserve.
  /// @param _totalReserveLiquidityToken The liquidity token reserve.
  function updateReserves(
    uint256 _totalReserveUnderlying,
    uint256 _totalReserveVaultReward,
    uint256 _totalReserveLiquidityToken
  ) external onlyGovernor {
    totalReserveUnderlying = _totalReserveUnderlying;
    totalReserveVaultReward = _totalReserveVaultReward;
    totalReserveLiquidityToken = _totalReserveLiquidityToken;

    emit ReservesUpdated(ReserveType.UNDERLYING, _totalReserveUnderlying);
    emit ReservesUpdated(ReserveType.VAULT_REWARD, _totalReserveVaultReward);
    emit ReservesUpdated(ReserveType.LIQUIDITY_TOKEN, _totalReserveLiquidityToken);
  }

  /********************************** Internal Functions **********************************/

  function _containAddress(address[] storage _list, address _item) internal view returns (bool) {
    for (uint256 i = 0; i < _list.length; i++) {
      if (_list[i] == _item) {
        return true;
      }
    }
    return false;
  }

  function _addOrRemoveAddress(
    address[] storage _list,
    mapping(address => bool) storage _status,
    address _item,
    bool _isAdd
  ) internal {
    require(_item != address(0), "Treasury: zero address");

    if (_isAdd) {
      require(!_status[_item], "Treasury: already set");
      if (!_containAddress(_list, _item)) {
        _list.push(_item);
      }
      _status[_item] = true;
    } else {
      require(_status[_item], "Treasury: already unset");
      _status[_item] = false;
    }
  }
}
