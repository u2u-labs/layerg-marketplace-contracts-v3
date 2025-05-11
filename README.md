
# 📘 LayerG Marketplace - Full Smart Contract Documentation

## Table of Contents

- [Overview](#overview)
- [Contract Structure](#contract-structure)
- [Core Contracts](#core-contracts)
- [Library Modules](#library-modules)
- [Example Flows](#example-flows)
- [Security Considerations](#security-considerations)
- [Tech Stack](#tech-stack)
- [License](#license)

---

## 🧬 Overview

LayerG is an on-chain NFT marketplace with support for:

- ERC721 & ERC1155 tokens
- Fixed-price and auction sales
- Collection-wide bidding
- Vault-based bid escrow
- Modular asset transfer agents
- Full signature validation (EOA & smart wallets)

---

## 📁 Contract Structure

```
Marketplace.sol
├── uses Validator (EIP712)
├── calls:
│   ├── AuctionVault.sol
│   └── AssetTransferAgent.sol
├── validates via:
│   ├── LibOrder.sol
│   ├── LibAuction.sol
│   ├── LibCollectionBid.sol
│   └── LibAsset.sol
```

---

## ⚙️ Core Contracts

### `Marketplace.sol`

Main contract responsible for:

- Order matching (`matchOrders`, `acceptBid`)
- Auctions (`submitAuctionBid`, `finalizeAuction`)
- Collection bids (`acceptCollectionBid`)
- Manages fee handling and calls external transfers

### `AuctionVault.sol`

Secure vault holding bid deposits:

- `deposit`: escrow ETH/ERC20 bids
- `refund`: returns overbid deposits
- `finalize`: pays out winning bids
- `emergencyWithdraw`: fallback for stuck funds

### `AssetTransferAgent.sol`

Handles actual asset transfers:

- `transferERC721`
- `transferERC1155`
- `transferERC20`

Only callable by `Marketplace`.

### `Validator.sol`

EIP-712 domain + hash helpers:

- `hashOrder`, `hashAuction`, `hashCollectionBid`
- `validateOrderSigner` (EOA or ERC1271 smart wallets)
- `validateBulkOrderItem` using Merkle proof

---

## 🧩 Library Modules

### `LibOrder.sol`

Defines fixed-price order structure and helpers:

```solidity
enum OrderType { BID, ASK, BULK }

struct Order {
  OrderType orderType;
  OrderItem[] items;
  address maker;
  address taker;
  bytes32 root;
  uint256 salt;
  bytes signature;
}
```

Includes:

- `hash(order)`
- `isExpired(order, index)`
- `recoverSigner(orderHash, signature)`

---

### `LibAuction.sol`

Signed auction object used off-chain:

```solidity
struct Auction {
  address maker;
  Asset asset;
  uint256 startPrice;
  uint256 buyNowPrice;
  uint256 startTime;
  uint256 endTime;
  uint256 salt;
  bytes signature;
}
```

---

### `LibCollectionBid.sol`

Supports signed bid for entire ERC721 collection:

```solidity
struct CollectionBid {
  address bidder;
  Asset makeAssetPerItem;
  address collectionAddress;
  uint256 maxQuantity;
  uint256 start;
  uint256 end;
  uint256 salt;
  bytes signature;
}
```

---

### `LibAsset.sol`

Used in all orders, auctions, and bids:

```solidity
enum AssetType { NATIVE, ERC20, ERC1155, ERC721 }

struct Asset {
  AssetType assetType;
  address contractAddress;
  uint256 assetId;
  uint256 assetAmount;
}
```

---

## 🔁 Example Flows

### 🛒 Match Fixed Price Order

1. Seller signs `Order`
2. Buyer calls `matchOrders`
3. Contract validates both, transfers assets and applies fee

---

### 🕒 Auction Bidding

1. Seller signs `Auction`
2. Bidder submits ETH using `submitAuctionBid`
3. Contract checks previous bid and vaults new deposit
4. Auction ends → `finalizeAuction()` sends NFT + payout

---

### 🎯 Collection Bid

1. Bidder signs `CollectionBid`
2. Seller with matching collection NFT calls `acceptCollectionBid`
3. Contract verifies signature, NFT ownership, and transfers

---

## 🔐 Security Considerations

- **Vault-based escrow**: isolates funds
- **ReentrancyGuard**: all external transfers protected
- **Pausable**: circuit breaker for all entry points
- **ERC1271**: contract wallet compatibility
- **Merkle Proofs**: scalable bulk listing support

---

## 🔧 Tech Stack

- Solidity `^0.8.20`
- OpenZeppelin: access, security, token utils
- EIP-712: off-chain signatures
- ERC721, ERC1155, ERC20 compatible

---

## 📄 License

MIT License © LayerG 2024

---

## 🔐 Security Considerations

The LayerG marketplace is built with security-first design principles:

### ✅ Vault-Based Deposit System
- Bids are deposited into `AuctionVault`, not stored in the marketplace.
- Funds are only moved on `refund`, `finalize`, or `emergencyWithdraw`.

### ✅ Reentrancy Protection
- All external calls (deposit, refund, finalize) use `nonReentrant`.

### ✅ Signature Verification
- All off-chain data uses EIP-712 signing with domain separators.
- Supports both EOAs and smart wallets via ERC1271.

### ✅ Pausable Circuit Breaker
- Admin can pause marketplace or vault during emergency using `pause()`.

### ✅ Time-locked Emergency Withdrawals
- Users can self-withdraw from vault after timeout if auction becomes stuck.

---

## ⚙️ Setup and Deployment

### 1. Deploy `AssetTransferAgent`

```solidity
AssetTransferAgent agent = new AssetTransferAgent();
```

### 2. Deploy `AuctionVault` with operator set to marketplace address

```solidity
AuctionVault vault = new AuctionVault(address(0)); // placeholder for operator
```

### 3. Deploy `Marketplace`

```solidity
Marketplace market = new Marketplace(
  feeRecipient,
  address(agent),
  address(vault),
  feeBps // example: 250 = 2.5%
);
```

### 4. Set Marketplace as operator

```solidity
agent.setMarketplace(address(market));
vault.setOperator(address(market));
```

### 5. Set Role Configuration

```solidity
market.setFeeRecipient(feeRecipient);
market.setAssetTransferAgent(address(agent));
market.setAuctionVault(address(vault));
market.setFeeBps(250); // 2.5%
```