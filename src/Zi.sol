pragma solidity >=0.8.0;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {SafeMath} from "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import {MinterControl} from "./MinterControl.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

// ￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚﾳﾳￔﾤￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￎￋￋﾳￅￋￋￋﾳￚￛￔﾤￚￚￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￋￋￋﾳﾡￋￋￋﾧￛￋￋￋﾳￚￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￚￔﾳﾳﾤￛￋￋﾳﾡￋￋￋﾳￋￋﾳﾧￚￚￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￋￋￋￋￋﾧￋￋￅￛￋￋￋￅￋﾳﾳﾳﾳﾳﾳￋￋￋﾤￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￇￋￅﾳￋￅￋￋￋￋￋￄﾡﾡﾡﾡﾡﾡﾡﾡￇￋﾧￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￔﾳﾳﾳﾳￋￋￋￋﾳﾤￚￇￋￋￋￋￋﾳﾳﾤￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￇￋￋￅﾡￚￚﾤￋￋￋﾳﾧￚￃￋￋﾤﾡￋￋￋￋￋﾳﾤￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚﾤￋￋￋￋﾧￚￚￛￋￋￋﾳﾳﾳﾳﾤﾡￋￋￋￋￋￋￋﾳￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￔￋￔￋￋￋﾳﾧￚￛￋￋﾳￋￋￅﾡﾡﾡￋￋￋﾳﾤﾡￇￋￋￋￋﾤￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￕￋￋￋￋﾳﾡￚￎﾳﾧￚￚￚￅￋﾴﾳﾳﾤￚￚￋￋￋﾳￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚﾡﾡﾡￚￋￋￋￋￚￋￋﾳￚￋￋﾤￇￋￋￋﾤￋￋￋￂￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￛￋﾧￚￋￋￅￚￅￋﾳￋￋﾳￋﾤￋￋￋￂￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￕￋﾳￕﾳￚￚￚￅￋﾳﾤￚￚￛￋￋￋￋￋￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￋￋﾳￂￚￚￚￚￃￋﾤￚﾡￋￋￋￋￋￋﾳￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￚﾡﾧￚￚￚￚￎￋￋﾤￚￚￚￚﾡￇￋﾤￚￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￋￋﾤￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚ
// ￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚￚ

contract Zi is Context, ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 public initialSupply;
    uint256 public supplyLimit;

    constructor(
        uint256 _initialSupply,
        uint256 _supplyLimit
    ) ERC20("Zi", "ZI") {
        initialSupply = _initialSupply;
        supplyLimit = _supplyLimit;
        // uint256(10 ** 6) * 10 ** super.decimals();
        _mint(_msgSender(), initialSupply);
    }

    address[] public minterAddresses;
    mapping(address => bool) public minters;
    mapping(address => uint256) public minterAllowance;
    mapping(address => bool) public enabledMinters;

    event Issue(uint256 amount);
    event Redeem(uint256 amount);
    event MintedByMinter(uint256 amount, address minter);
    event BurnedByMinter(uint256 amount, address minter);
    event MinterConfigured(address indexed minter, uint256 minterAllowance);

    modifier onlyMinters() {
        require(minters[_msgSender()], "Not on the allow list");
        _;
    }
    modifier whenNotDisabled(address minter) {
        require(enabledMinters[minter], "Minter not enabled");
        _;
    }

    /// @dev checks if it is on the minterAddresses array

    function isMinter(address minter) public view returns (bool) {
        for (uint i = 0; i < minterAddresses.length; i++) {
            if (minterAddresses[i] == minter) {
                return true;
            }
        }
        return false;
    }

    function remainingSupply() public view returns (uint256) {
        return supplyLimit - totalSupply();
    }

    function mint(
        address account,
        uint256 amount
    ) public nonReentrant onlyOwner {
        uint256 newTotalSupply = super.totalSupply() + amount;
        require(newTotalSupply <= supplyLimit, "Hitting supply limit");
        _mint(account, amount);
    }

    function burn(
        address account,
        uint256 amount
    ) public nonReentrant onlyOwner {
        require(account == _msgSender(), "Burning other people's tokens!");
        uint256 newTotalSupply = super.totalSupply() - amount;
        require(newTotalSupply > 0, "You cannot burn the entire supply");
        _burn(account, amount);
    }

    function mintByMinter(
        address to,
        uint256 amount
    ) public nonReentrant whenNotDisabled(msg.sender) onlyMinters {
        uint256 balance = minterAllowance[msg.sender];
        require(balance > amount, "Insufficient allowance");
        require(
            totalSupply().add(amount) > totalSupply(),
            "issuing negative amount to total supply"
        );

        require(
            balanceOf(to).add(amount) > balanceOf(to),
            "issuing negative amount to owner"
        );

        _mint(to, amount);
        minterAllowance[msg.sender] = balance.sub(amount);

        emit MintedByMinter(amount, to);
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the blaance must be enough to cover the redemption
    // or the call will fail.
    function burnByMinter(
        address from,
        uint256 amount
    ) public nonReentrant whenNotDisabled(msg.sender) onlyMinters {
        require(totalSupply() >= amount);
        require(balanceOf(from) >= amount);
        uint256 balance = minterAllowance[msg.sender];
        _burn(from, amount);
        minterAllowance[msg.sender] = balance.add(amount);
        emit BurnedByMinter(amount, from);
    }

    function configureMinter(
        address minter,
        uint256 allowance
    ) external onlyOwner returns (bool) {
        require(minter != owner(), "You cannot add the owner!");
        require(allowance <= remainingSupply(), "allowance is too big");
        minters[minter] = true;
        enabledMinters[minter] = true;
        minterAllowance[minter] = allowance;

        minterAddresses.push(minter);
        emit MinterConfigured(minter, allowance);
        return true;
    }

    function oneBipOfTotalSupply() public view returns (uint256) {
        return totalSupply().div(uint256(10000));
    }

    function allMinters() public view returns (address[] memory) {
        return minterAddresses;
    }

    function removeMinter(address minter) external onlyOwner returns (bool) {
        require(minter != address(0), "Zero address!");
        require(minter != owner(), "You cannot remove the owner!");
        require(isMinter(minter), "Address not on list of minter addresses!");
        delete minters[minter];
        delete minterAllowance[minter];

        for (uint256 i = 0; i < minterAddresses.length; i++) {
            // if the programme finds a slot in the array whose entry is the minter
            // it replaces it with the last element in the array
            if (minterAddresses[i] == minter) {
                minterAddresses[i] = minterAddresses[
                    minterAddresses.length - 1
                ];
                minterAddresses.pop();
                break;
            }
        }
        return true;
    }

    ///@dev  to enable a minter, the address must be already added to minterAddress
    // if the minter is already enabled, the function enables it again
    function enableMinter(address minter) public onlyOwner returns (bool) {
        require(isMinter(minter), "Address is not a minter!");
        enabledMinters[minter] = true;
        return enabledMinters[minter];
    }

    ///@dev  to disable a minter, the address must be already added to minterAddress
    // if the minter is already disabled, the function disables it again
    function disableMinter(address minter) public onlyOwner returns (bool) {
        require(isMinter(minter), "Address is not a minter!");
        enabledMinters[minter] = false;
        return enabledMinters[minter];
    }

    function enableAllMinters() public onlyOwner returns (bool success) {
        success = true;
        for (uint256 i = 0; i < minterAddresses.length; i++) {
            enabledMinters[minterAddresses[i]] = true;
            success = success && enabledMinters[minterAddresses[i]];
        }
        return success;
    }

    function disableAllMinters() public onlyOwner returns (bool success) {
        success = true;

        for (uint256 i = 0; i < minterAddresses.length; i++) {
            enabledMinters[minterAddresses[i]] = false;
            success = success && !enabledMinters[minterAddresses[i]];
        }
        return success;
    }

    function rescueERC20(
        address tokenAddress,
        address to
    ) public onlyOwner returns (bool) {
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
        bool success = IERC20(tokenAddress).transfer(to, amount);
        return success;
    }
}
