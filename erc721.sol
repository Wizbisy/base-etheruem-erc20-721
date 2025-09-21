// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
AdvancedERC721.sol

GUIDE FOR DEPLOYMENT VIA REMIX IDE:
----------------------------------
1. Open https://remix.ethereum.org
2. In the File Explorer, create a new file named "AdvancedERC721.sol" and paste this code.
3. In the left sidebar, select the "Solidity Compiler" tab.
   - Set compiler version to ^0.8.20
   - Click "Compile AdvancedERC721.sol"
4. Go to the "Deploy & Run Transactions" tab.
   - Environment: Injected Provider (if using MetaMask) or Remix VM for testing.
   - Contract: Select AdvancedERC721.
   - Enter constructor arguments:
        • name_ (string): Collection name (e.g., "MyNFT").
        • symbol_ (string): Token symbol (e.g., "MNFT").
        • baseURI_ (string): Base URI for token metadata (e.g., "ipfs://.../").
        • maxSupply_ (uint256): Maximum number of NFTs (0 = unlimited).
        • royaltyRecipient_ (address): Address to receive royalties.
        • royaltyFeeBps_ (uint96): Royalty fee in basis points (e.g., 500 = 5%).
   - Click "Deploy".
5. Interact with your deployed contract from the Remix UI.

Features included:
 - ERC721 standard (NFT)
 - ERC721Burnable
 - ERC721Enumerable (list all NFTs)
 - Pausable (admin can pause transfers)
 - Ownable (admin functions)
 - Base URI management
 - Minting (owner only)
 - Supply cap (0 = unlimited)
 - Blacklist system
 - Royalty support (EIP-2981)
 - Rescue functions for ETH and tokens
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AdvancedERC721 is ERC721Enumerable, ERC721Burnable, ERC721Pausable, ERC2981, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string private _baseTokenURI;
    uint256 public maxSupply; // 0 = unlimited

    mapping(address => bool) public isBlacklisted;

    event BaseURIChanged(string oldBaseURI, string newBaseURI);
    event MaxSupplyChanged(uint256 oldSupply, uint256 newSupply);
    event BlacklistUpdated(address indexed account, bool blacklisted);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 maxSupply_,
        address royaltyRecipient_,
        uint96 royaltyFeeBps_
    ) ERC721(name_, symbol_) {
        _baseTokenURI = baseURI_;
        maxSupply = maxSupply_;

        if (royaltyRecipient_ != address(0) && royaltyFeeBps_ > 0) {
            _setDefaultRoyalty(royaltyRecipient_, royaltyFeeBps_);
        }
    }

    // ------------------ Admin functions ------------------
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        emit BaseURIChanged(_baseTokenURI, newBaseURI);
        _baseTokenURI = newBaseURI;
    }

    function setMaxSupply(uint256 newMax) external onlyOwner {
        emit MaxSupplyChanged(maxSupply, newMax);
        maxSupply = newMax;
    }

    function updateBlacklist(address account, bool blacklisted) external onlyOwner {
        isBlacklisted[account] = blacklisted;
        emit BlacklistUpdated(account, blacklisted);
    }

    function setRoyalty(address recipient, uint96 feeBps) external onlyOwner {
        _setDefaultRoyalty(recipient, feeBps);
    }

    function mint(address to) external onlyOwner {
        require(to != address(0), "zero address");
        if (maxSupply > 0) {
            require(_tokenIdCounter.current() < maxSupply, "max supply reached");
        }
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    // ------------------ Overrides ------------------
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable, ERC721Pausable)
    {
        require(!paused(), "transfers paused");
        if (from != address(0)) require(!isBlacklisted[from], "sender blacklisted");
        if (to != address(0)) require(!isBlacklisted[to], "recipient blacklisted");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // ------------------ Rescue Functions ------------------
    function rescueERC20(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "zero recipient");
        IERC20(tokenAddress).transfer(to, amount);
    }

    function rescueETH(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "zero recipient");
        to.transfer(amount);
    }

    receive() external payable {}
    fallback() external payable {}
}
