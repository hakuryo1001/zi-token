pragma solidity >=0.8.0;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
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

contract Zi is Context, ERC20, MinterControl, ReentrancyGuard {
    using SafeMath for uint256;
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
    ) public nonReentrant onlyMinters {
        require(
            totalSupply() + amount > totalSupply(),
            "issuing negative amount to total supply"
        );

        require(
            balanceOf(to) + amount > balanceOf(to),
            "issuing negative amount to owner"
        );

        _mint(to, amount);
        emit MintedByMinter(amount, to);
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the blaance must be enough to cover the redemption
    // or the call will fail.
    function burnByMinter(
        address to,
        uint256 amount
    ) public nonReentrant onlyMinters {
        require(totalSupply() >= amount);
        require(balanceOf(to) >= amount);
        _burn(to, amount);
        emit BurnedByMinter(amount, to);
    }

    function oneBipOfTotalSupply() public view returns (uint256) {
        return totalSupply().div(uint256(10000));
    }

    event Issue(uint256 amount);
    event Redeem(uint256 amount);
    event MintedByMinter(uint256 amount, address minter);
    event BurnedByMinter(uint256 amount, address minter);
}
