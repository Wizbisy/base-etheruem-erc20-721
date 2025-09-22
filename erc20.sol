// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
AdvancedERC20.sol

GUIDE FOR DEPLOYMENT VIA REMIX IDE:
----------------------------------
1. Open https://remix.ethereum.org
2. In the File Explorer, create a new file named "AdvancedERC20.sol" and paste this code.
3. In the left sidebar, select the "Solidity Compiler" tab.
   - Set compiler version to ^0.8.20
   - Click "Compile AdvancedERC20.sol"
4. Go to the "Deploy & Run Transactions" tab.
   - Environment: Injected Provider (if using MetaMask) or Remix VM for testing.
   - Contract: Select AdvancedERC20.
   - Enter constructor arguments:
        • name_ (string): Name of the token (e.g., "MyToken").
        • symbol_ (string): Symbol of the token (e.g., "MTK").
        • initialSupply (uint256): Initial supply in wei (e.g., 1000000 * 10**18).
        • feeRecipient (address): Address that will receive transaction fees.
        • transferFeeBP (uint256): Transaction fee in basis points (e.g., 100 = 1%).
        • cap (uint256): Maximum supply (0 = no cap).
   - Click "Deploy".
5. Interact with your deployed contract from the Remix UI.

Features included:
 - ERC20 standard
 - ERC20Burnable
 - ERC20Snapshot (owner can snapshot balances)
 - ERC20Permit (EIP-2612 permit)
 - Pausable (owner can pause transfers)
 - Ownable (admin functions)
 - Transfer fee (configurable)
 - Anti-whale protections (max transaction and wallet balance)
 - Blacklist system
 - Optional supply cap
 - Rescue functions for ETH and tokens
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AdvancedERC20 is ERC20, ERC20Burnable, ERC20Snapshot, ERC20Permit, Pausable, Ownable {
    using SafeMath for uint256;

    uint256 public transferFeeBP; // fee in basis points (e.g., 100 = 1%).
    address public feeRecipient;

    uint256 public maxTxAmount; // anti-whale: max per transfer (0 = disabled)
    uint256 public maxWalletBalance; // anti-whale: max per wallet (0 = disabled)

    uint256 public cap; // optional supply cap (0 = no cap)

    mapping(address => bool) public isBlacklisted;

    event FeeRecipientChanged(address indexed oldRecipient, address indexed newRecipient);
    event TransferFeeChanged(uint256 oldBP, uint256 newBP);
    event MaxTxAmountChanged(uint256 oldAmount, uint256 newAmount);
    event MaxWalletBalanceChanged(uint256 oldAmount, uint256 newAmount);
    event CapChanged(uint256 oldCap, uint256 newCap);
    event BlacklistUpdated(address indexed account, bool blacklisted);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        address feeRecipient_,
        uint256 transferFeeBP_,
        uint256 cap_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        require(feeRecipient_ != address(0), "fee recipient zero");
        require(transferFeeBP_ <= 1000, "fee too high"); // safety: <=10%

        feeRecipient = feeRecipient_;
        transferFeeBP = transferFeeBP_;
        cap = cap_;

        if (initialSupply > 0) {
            if (cap == 0) {
                _mint(msg.sender, initialSupply);
            } else {
                require(initialSupply <= cap, "initial > cap");
                _mint(msg.sender, initialSupply);
            }
        }

        maxTxAmount = 0;
        maxWalletBalance = 0;
    }

    function snapshot() external onlyOwner { _snapshot(); }
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "zero recipient");
        emit FeeRecipientChanged(feeRecipient, newRecipient);
        feeRecipient = newRecipient;
    }

    function setTransferFeeBP(uint256 newBP) external onlyOwner {
        require(newBP <= 2000, "max 20% allowed");
        emit TransferFeeChanged(transferFeeBP, newBP);
        transferFeeBP = newBP;
    }

    function setMaxTxAmount(uint256 newMax) external onlyOwner {
        emit MaxTxAmountChanged(maxTxAmount, newMax);
        maxTxAmount = newMax;
    }

    function setMaxWalletBalance(uint256 newMax) external onlyOwner {
        emit MaxWalletBalanceChanged(maxWalletBalance, newMax);
        maxWalletBalance = newMax;
    }

    function setCap(uint256 newCap) external onlyOwner {
        emit CapChanged(cap, newCap);
        cap = newCap;
    }

    function updateBlacklist(address account, bool blacklisted) external onlyOwner {
        isBlacklisted[account] = blacklisted;
        emit BlacklistUpdated(account, blacklisted);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        if (cap > 0) {
            require(totalSupply().add(amount) <= cap, "cap exceeded");
        }
        _mint(to, amount);
    }

    function rescueERC20(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "zero recipient");
        IERC20(tokenAddress).transfer(to, amount);
    }

    function rescueETH(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "zero recipient");
        to.transfer(amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "token transfer while paused");

        if (from != address(0)) { require(!isBlacklisted[from], "sender blacklisted"); }
        if (to != address(0)) { require(!isBlacklisted[to], "recipient blacklisted"); }

        if (maxTxAmount > 0 && from != address(0) && to != address(0)) {
            require(amount <= maxTxAmount, "exceeds max tx amount");
        }

        if (maxWalletBalance > 0 && to != address(0) && from != to) {
            uint256 newBal = balanceOf(to).add(amount);
            require(newBal <= maxWalletBalance, "exceeds max wallet balance");
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (transferFeeBP == 0 || sender == feeRecipient || recipient == feeRecipient) {
            super._transfer(sender, recipient, amount);
            return;
        }

        uint256 fee = amount.mul(transferFeeBP).div(10000);
        uint256 afterFee = amount.sub(fee);

        super._transfer(sender, feeRecipient, fee);
        super._transfer(sender, recipient, afterFee);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal override(ERC20) { super._mint(account, amount); }
    function _burn(address account, uint256 amount) internal override(ERC20) { super._burn(account, amount); }

    receive() external payable {}
    fallback() external payable {}
}
