# Ethereum ERC20 & ERC721 Contracts (Base Compatible)

This repository contains ready-to-use smart contract templates for **ERC20** and **ERC721** tokens, built with [OpenZeppelin](https://openzeppelin.com/contracts/) and extended features.  
Both contracts are fully compatible with the **Base network** (L2 built on Optimism) and can be deployed on **Base Sepolia (testnet)** or **Base Mainnet**.

---

## 📦 Contracts

### 🔹 AdvancedERC20.sol
- ERC20 standard
- Minting & Burning
- Pausing (admin can pause transfers)
- Blacklist support
- Supply cap (max supply limit)
- Fee logic (optional)
- Rescue functions for ETH and tokens

### 🔹 AdvancedERC721.sol
- ERC721 standard (NFTs)
- Minting & Burning
- Enumerable (track all NFTs)
- Pausable
- Blacklist support
- Max supply (0 = unlimited)
- Base URI management
- Royalties (EIP-2981 standard)
- Rescue functions for ETH and tokens

---

## 🚀 Deployment on Base (via Remix)

1. Go to [Remix IDE](https://remix.ethereum.org).
2. In the file explorer, create a new file and paste one of the contracts (`AdvancedERC20.sol` or `AdvancedERC721.sol`).
3. Open the **Solidity Compiler** tab:
   - Set version to `^0.8.20`
   - Click **Compile**
4. Go to the **Deploy & Run Transactions** tab:
   - Environment: **Injected Provider** (MetaMask connected to Base Sepolia or Base Mainnet)
   - Contract: Select your contract (`AdvancedERC20` or `AdvancedERC721`)
   - Enter constructor arguments (name, symbol, baseURI, max supply, royalty info, etc.)
   - Click **Deploy**
5. Confirm the transaction in MetaMask.  
6. Verify your contract on [BaseScan](https://basescan.org) or [Base SepoliaScan](https://sepolia.basescan.org).

---

## 🛠️ Example RPCs

- **Base Sepolia Testnet**

https://sepolia.base.org Chain ID: 84532 Currency: ETH

- **Base Mainnet**

https://mainnet.base.org Chain ID: 8453 Currency: ETH

You can add these networks manually in MetaMask or import them from [chainlist.org](https://chainlist.org).

---

## 📖 Example Usage

### Deploy ERC20
```solidity
constructor(
string memory name_,
string memory symbol_,
uint256 initialSupply_,
uint256 maxSupply_,
uint256 feeBasisPoints_
)
```

### Deploy ERC721
```solidity
constructor(
  string memory name_,
  string memory symbol_,
  string memory baseURI_,
  uint256 maxSupply_,
  address royaltyRecipient_,
  uint96 royaltyFeeBps_
)
```

---

### 🧑‍💻 Contribution

This repo is part of my learning and building journey in the Base ecosystem.
Pull requests, issues, and suggestions are welcome!


---

### 📜 License

MIT License

---
