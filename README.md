# LayerG Marketplace Contracts

A comprehensive and flexible NFT marketplace smart contract supporting multiple asset types, order matching, auctions, and collection bids.

This repository contains the contracts for the LayerG Marketplace project:

- [LayerG Marketplace Contracts](./contracts)

## Deploy contract

- Run: npx hardhat run scripts/deploy.ts --network <your_network>

## Overview

This marketplace smart contract provides a decentralized platform for trading NFTs (ERC721 and ERC1155) and tokens (ERC20) with support for:

- Order matching
- Auctions with configurable parameters
- Collection-wide bidding
- Marketplace fees
- Bulk order processing

The contract is built with security in mind, implementing reentrancy guards, pausability, and ownership controls.

## Features

### Asset Support
- ERC721
- ERC1155
- ERC20
- Native cryptocurrency

### Trading Mechanisms

#### Order Matching
- Create and fill orders with flexible asset types
- Cancel orders when needed
- Partial filling of orders
- Bulk order processing

#### Auctions
- Time-bound auctions with configurable duration
- Minimum bid increment enforcement
- Buy-now price support
- Automatic finalization when buy-now price is met

#### Collection Bidding
- Bid on any item within an NFT collection
- Set maximum quantity for collection bids
- Time-bound bid validity

### Security Features
- Reentrancy protection
- Pausable functionality
- Owner-only administrative functions
- Signature validation for orders and bids
- Emergency fund recovery mechanism

## Contract Architecture

The marketplace relies on several helper libraries and interfaces:

- `LibOrder`: Order data structures and validation
- `LibAsset`: Asset type definitions and operations
- `LibAuction`: Auction data structures and operations
- `LibCollectionBid`: Collection bid structures and validation
- `IAssetTransferAgent`: Interface for asset transfer operations
- `IAuctionVault`: Interface for auction bid management
- `Validator`: Base contract for signature validation

## Key Parameters

- `MAX_FEE_BPS`: Maximum fee in basis points (10000 = 100%)
- `MIN_AUCTION_DURATION`: Minimum allowed auction duration (1 hour)
- `MAX_AUCTION_DURATION`: Maximum allowed auction duration (30 days)
- `MIN_BID_INCREMENT_BPS`: Minimum increment for successive bids (100 = 1%)

## Main Functions

### Order Management

```solidity
function matchOrders(
    LibOrder.Order calldata makerOrder,
    LibOrder.Order calldata takerOrder,
    uint256 orderItemIndex,
    bytes32[] calldata proof
) external payable nonReentrant whenNotPaused
```
Match a maker's order with a taker's order to execute a trade.

```solidity
function batchMatchOrders(
    LibOrder.Order[] calldata makerOrders,
    LibOrder.Order calldata takerOrder,
    uint256[] calldata orderItemIndices,
    bytes32[][] calldata proofs
) external payable nonReentrant whenNotPaused
```
Match multiple maker orders with a single taker order in one transaction.

```solidity
function cancelOrder(
    LibOrder.Order calldata order,
    uint256 orderItemIndex
) external nonReentrant whenNotPaused
```
Cancel an order that hasn't been fully filled.

### Bidding

```solidity
function acceptBid(
    LibOrder.Order calldata bidOrder,
    uint256 orderItemIndex,
    uint256 sellAmount
) external nonReentrant whenNotPaused
```
Accept a bid from a buyer for your NFT.

```solidity
function acceptCollectionBid(
    LibCollectionBid.CollectionBid calldata bid,
    uint256 tokenId
) external nonReentrant
```
Accept a collection-wide bid for a specific tokenId you own.

### Auctions

```solidity
function submitAuctionBid(
    LibAuction.Auction calldata auction
) external payable nonReentrant whenNotPaused
```
Submit a bid for an active auction.

```solidity
function finalizeAuction(
    LibAuction.Auction calldata auction,
    bytes calldata signature
) external nonReentrant whenNotPaused
```
Finalize an auction after it has ended.

### Administrative Functions

```solidity
function setFeeRecipient(address _feeRecipient) external onlyOwner
```
Update the address that receives marketplace fees.

```solidity
function setFeeBps(uint256 _feeBps) external onlyOwner
```
Update the marketplace fee percentage (in basis points).

```solidity
function pause() external onlyOwner
```
Pause the marketplace in case of emergency.

```solidity
function unpause() external onlyOwner
```
Resume marketplace operations after pausing.

## Events

The contract emits various events to track marketplace activity:

- `OrderMatched`: Emitted when an order is successfully matched
- `CancelOrder`: Emitted when an order is cancelled
- `AuctionBidSubmitted`: Emitted when a bid is submitted for an auction
- `AuctionFinalized`: Emitted when an auction is finalized
- Various administrative events for parameter updates

## Setup and Deployment

The contract requires several parameters during deployment:

```solidity
constructor(
    address _feeRecipient,
    address _assetTransferAgent,
    address _auctionVault,
    uint256 _feeBps
)
```

- `_feeRecipient`: Address to receive marketplace fees
- `_assetTransferAgent`: Address of the asset transfer agent contract
- `_auctionVault`: Address of the auction vault contract
- `_feeBps`: Marketplace fee percentage in basis points (e.g., 250 = 2.5%)

## Security Considerations

- All external functions have reentrancy protection through the ReentrancyGuard
- The contract can be paused in case of emergency
- Owner functions are protected with the Ownable modifier
- Orders and auctions are validated using cryptographic signatures
- Emergency fund recovery is available for the contract owner
