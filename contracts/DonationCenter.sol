pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 * 
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/** 
 *
 * @dev A contract that is thought to create a Crowdsale for a token
 * representing a pyshical asset. This crowdsale is thought to be:
 *
 * - Pausable, so that the owner can pause it in case of emergency.
 * - Minted, so that tokens are minted directly.
 * - Mintable, so that tokens are directly minted during the crowdsale.
 * - Finalizable, so that it has a limited duration and has a finalization 
 *   procedure explained in _finalization().
 *
 */

contract DonationCenter {
    using SafeMath for uint;

    address private _dai;
    address private _donation_token;

    bytes4 private constant SELECTOR_MINT = bytes4(keccak256(bytes('mint(address,uint256)')));
    bytes4 private constant SELECTOR_BURN = bytes4(keccak256(bytes('burnFrom(address,uint256)')));
    bytes4 private constant SELECTOR_TRANSFER = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant SELECTOR_TRANSFER_FROM = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    event Donation (address indexed sender, uint256 amount);
    event Collection (address indexed sender, uint256 amount);
    
    event Debug(bool success);

    function _safeMint(address to, uint value) private {
        (bool success, bytes memory data) = _donation_token.call(abi.encodeWithSelector(SELECTOR_MINT, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Donation: TRANSFER_FAILED');
    }

    function _safeBurnFrom(address from, uint value) private {
        (bool success, bytes memory data) = _donation_token.call(abi.encodeWithSelector(SELECTOR_BURN, from, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Collect: TRANSFER_FAILED');
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR_TRANSFER, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Token transfer: TRANSFER_FAILED');
    }

    function _safeTransferFrom(address token, address _from, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR_TRANSFER_FROM, _from, to, value));
        emit Debug(success);
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Token transfer_from: TRANSFER_FAILED');
    }

    /** 
    *
    * @dev Creates a new donation center contracts to donate dais representing euros
    * to mint tokens so that they can be given for social matters.
    *
    * The tokens will be withdrawn from the contract _dai.
    * The tokens will be minted in contract _donation_token.
    */

   constructor(address dai, address donation_token) public {
       _dai = dai;
       _donation_token = donation_token;
    }

    function dai_address() public view returns (address) {
        return _dai;
    }
    
    function donation_token_address() public view returns (address) {
        return _donation_token;
    }
    
    /** 
    *
    * @dev  Stores `amount` dai tokens from the caller's account to the contract
    * and mints `amount`of donation tokens to the contract.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Donation} event.
    * 
    * The tokens will be withdrawn from the contract _dai.
    * The tokens will be minted in contract _donation_token.
    */
 
    function donate(uint256 dai_amount) public returns (bool) {
        require(dai_amount > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        _safeMint(address(this), dai_amount);
        _safeTransferFrom(_dai, msg.sender, address(this), dai_amount);
        emit Donation(msg.sender, dai_amount);
        return true;
    }

    /** 
    *
    * @dev Gives `amount` dai tokens from the contract's account to caller
    * and burns `amount`of donation tokens to the contract.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Collection} event.
    *
    * The tokens will be withdrawn from the contract _dai.
    * The tokens will be minted in contract _donation_token.
    */

    function collect_dai(uint256 dt_amount) public {
        require(dt_amount > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        _safeBurnFrom(msg.sender, dt_amount);
        _safeTransfer(_dai, msg.sender, dt_amount);
        emit Collection(msg.sender, dt_amount);
    }

     /** 
    *
    * @dev Gives `amount` dai tokens from the contract's account to caller
    * and burns `amount`of donation tokens to the contract.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Collection} event.
    *
    * The tokens will be withdrawn from the contract _dai.
    * The tokens will be minted in contract _donation_token.
    */
    
    function getSubidy() public {
        (,uint last_month,) = _daysToDate(subsidies_registry[msg.sender]);
        (,uint actual_month,) = _daysToDate(block.timestamp);
        require(_safeIsSubsidy(msg.sender), 'Subsidy not accepted');
        require(last_month < actual_month, 'Subsidy already given');
        _safeTransfer(_donation_token, msg.sender, 100);
        emit Subsidy(msg.sender, 100);
        subsidies_registry[msg.sender] = actual_month;
    }

}