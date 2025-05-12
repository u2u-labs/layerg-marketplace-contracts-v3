

# 📘 LayerG Marketplace - Full Smart Contract Documentation

## Table of Contents

- [🧬 Overview](#-overview)
- [📁 Contract Structure](#-contract-structure)
- [⚙️ Core Contracts](#-core-contracts)
- [🧩 Library Modules](#-library-modules)
- [🔁 Example Flows](#-example-flows)
  - [🛒 Match Fixed Price Order](#-match-fixed-price-order)
  - [🕒 Auction Bidding](#-auction-bidding)
  - [🎯 Collection Bid](#-collection-bid)
  - [🧩 `batchMatchOrders` Flow](#-batchmatchorders-flow)
  - [🌳 `validateBulkOrderItem` Flow](#-validatebulkorderitem-flow)
- [🔐 Security Considerations](#-security-considerations)
- [⚙️ Setup and Deployment](#️-setup-and-deployment)
- [🧱 Tech Stack](#-tech-stack)
- [📄 License](#-license)


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

---

## 🔁 Bulk Order Support

### 🧩 `batchMatchOrders` Flow

Used to match multiple maker orders against a single taker order in one transaction.

1. Taker submits:
   - Array of `makerOrders`
   - Single `takerOrder`
   - `orderItemIndices`: indices of each item being matched in respective makerOrders
   - `proofs`: Merkle proofs (if maker order type is BULK)

2. For each order:
   - `validateOrderSigner()` checks signature
   - `validateIfMatchedBothSide()` checks asset compatibility
   - If type == `OrderType.BULK`, `validateBulkOrderItem()` verifies Merkle proof
   - Transfers assets using `_transferWithFee()`

✅ Saves gas by batching many order fills into a single transaction.

---

### 🌳 `validateBulkOrderItem` Flow

Used to validate a bulk order’s Merkle-leaf encoded item.

1. Each maker order of type `BULK` contains:
   - `root` (Merkle root of all item hashes)
   - Off-chain signature for root

2. Each `OrderItem` being executed must:
   - Provide its Merkle proof in the `proofs[]` array
   - Be verifiable via `validateBulkOrderItem()`:
     ```solidity
     function validateBulkOrderItem(
         OrderItem calldata orderItem,
         bytes32 root,
         bytes32[] calldata proof
     ) internal pure {
         bytes32 leaf = hashOrderItem(orderItem);
         require(verifyMerkleProof(proof, root, leaf), "Invalid Merkle proof");
     }
     ```

🔐 This reduces gas usage by keeping large listings off-chain and only verifying necessary items on-chain.

---

## ✅ Example Bulk Order Flow

1. Seller signs `OrderType.BULK` with `root = keccak256([...orderItemHashes])`
2. Buyer submits:
   - `batchMatchOrders(...)`
   - Includes only the items they want to match
   - Includes valid proof for each item
3. Contract:
   - Validates each item exists in the tree
   - Executes transfers

