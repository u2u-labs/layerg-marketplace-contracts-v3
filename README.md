# LayerG Marketplace Smart Contracts Documentation

## Overview
LayerG Marketplace is a feature-rich, decentralized NFT and digital asset trading protocol. It supports:

- **Order Matching** (ASK, BID, BULK)
- **Collection Bids** (on ERC721 collections)
- **Time-based Auctions** with optional Buy-Now
- **Native, ERC20, ERC721, ERC1155 asset support**
- **Modular roles**: Asset Transfer Agent, Auction Vault
- **EIP-712 Off-chain Signature Verification**

---

## Contracts Structure

```
contracts/
├── Marketplace.sol              # Core marketplace logic
├── Validator.sol               # Signature validation using EIP-712
├── AuctionVault.sol            # Secure fund escrow for auction bids
├── AssetTransferAgent.sol      # Asset movement manager
├── interfaces/
│   └── IAssetTransferAgent.sol
│   └── IAuctionVault.sol
├── libraries/
│   └── LibOrder.sol            # Order structs + hashing
│   └── LibAuction.sol          # Auction structs + hashing
│   └── LibCollectionBid.sol    # Collection bid structs + hashing
│   └── LibAsset.sol            # Common asset definition
│   └── MerkleProof.sol         # Merkle proof verification for BULK
```

---

## Key Flows

### 1. Order Matching (ASK/BID)
1. Maker signs an order with multiple items
2. Taker constructs a matching order
3. Calls `matchOrders()`
4. Assets exchanged via `AssetTransferAgent`

### 2. Bulk Orders (Merkle root)
1. Maker generates Merkle tree of `OrderItem`s
2. Shares root in order
3. Taker provides leaf + proof during `matchOrders()`

### 3. Collection Bidding
1. Bidder signs `CollectionBid`
2. Seller calls `acceptCollectionBid()` with tokenId
3. Bid amount sent from bidder -> seller, NFT transferred

### 4. Auctions
1. Maker signs `Auction` struct (off-chain)
2. Bidders call `submitAuctionBid()` with signature
3. Funds escrowed in `AuctionVault`
4. Highest bidder can auto-win if `buyNowPrice` met
5. Otherwise, anyone can call `finalizeAuction()` after end time

---

## Key Structs

### LibAsset.Asset
```solidity
struct Asset {
  AssetType assetType; // NATIVE, ERC20, ERC721, ERC1155
  address contractAddress;
  uint256 assetId;
  uint256 assetAmount;
}
```

### LibOrder.Order
```solidity
struct Order {
  OrderType orderType; // BID, ASK, BULK
  OrderItem[] items;
  address maker;
  address taker; // Optional (used in match validation)
  bytes32 root; // Used in BULK orders
  uint256 salt;
  bytes signature;
}
```

### LibAuction.Auction
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

### LibCollectionBid.CollectionBid
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

## Functions Reference

### Marketplace.sol
- `matchOrders()` - Fills an order item with a matching counter-order
- `batchMatchOrders()` - Batch fill multiple maker orders
- `cancelOrder()` - Maker cancels their order
- `acceptBid()` - Seller accepts a bid order
- `acceptCollectionBid()` - Accept collection bid
- `submitAuctionBid()` - Place auction bid, triggers auto-finalize if `buyNowPrice` met
- `finalizeAuction()` - Finalize after auction ends manually
- `pause()` / `unpause()` / `setFeeRecipient()` / `setAssetTransferAgent()` - Admin management

### AuctionVault.sol
- `deposit()` - Escrow funds (called by Marketplace)
- `refund()` - Refund losing bidder
- `finalize()` - Release funds to seller
- `emergencyWithdraw()` - Emergency claim by bidder

### AssetTransferAgent.sol
- `transferERC20()` / `transferERC721()` / `transferERC1155()` - Marketplace-only transfer calls

---

## Deployment and Setup

1. **Deploy AssetTransferAgent**
2. **Deploy AuctionVault** with Marketplace address
3. **Deploy Marketplace** with:
   - `feeRecipient`
   - `assetTransferAgent`
   - `auctionVault`
   - `feeBps`
4. **Set Marketplace as operator** in:
   - `AuctionVault.setOperator()`
   - `AssetTransferAgent.setMarketplace()`

---

## Security Considerations

- **Reentrancy Protection**: All external transfer/mutating functions are guarded by `nonReentrant`
- **Escrow Design**: Marketplace does not hold user funds; `AuctionVault` handles refunds and claims securely
- **EIP-712 Signature Verification**: Ensures off-chain signatures can't be spoofed (via `Validator.sol`)
- **Finalization Logic**: Auction finalization logic ensures asset exists before payment release
- **Bulk Order Validity**: Uses Merkle proof verification for efficient order tree validation
- **Emergency Withdraw**: Bidder can claim after delay in case of stalled auction
