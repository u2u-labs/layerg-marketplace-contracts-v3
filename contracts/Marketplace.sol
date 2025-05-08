// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./libraries/LibOrder.sol";
import "./libraries/LibAsset.sol";
import "./libraries/LibAuction.sol";
import "./libraries/LibCollectionBid.sol";
import "./interfaces/IAssetTransferAgent.sol";
import "./Validator.sol";
import "./interfaces/IAuctionVault.sol";

/**
 * @title Marketplace
 * @notice NFT Marketplace supporting order matching, auctions, and bidding functionality
 * @dev Handles various asset types (ERC20, ERC721, ERC1155, and native tokens)
 */
contract Marketplace is ReentrancyGuard, Ownable, Pausable, Validator {
    using ECDSA for bytes32;

    // Constants
    uint256 public constant MAX_FEE_BPS = 10000;
    uint256 public constant MIN_AUCTION_DURATION = 1 hours;
    uint256 public constant MAX_AUCTION_DURATION = 30 days;
    uint256 public constant MIN_BID_INCREMENT_BPS = 100; //

    // State variables
    address public feeRecipient;
    address public assetTransferAgent;
    address public auctionVault;
    uint256 public feeBps;

    // Order tracking
    mapping(bytes32 => mapping(uint256 => uint256)) public orderFillAmount;
    mapping(bytes32 => mapping(uint256 => bool)) private cancelledOrders;

    // Auction tracking
    mapping(bytes32 => LibAuction.Bid) public highestBids;
    mapping(bytes32 => bool) public auctionFinalized;

    // Collection bid tracking
    mapping(bytes32 => uint256) public collectionBidFillAmount;

    // Events
    event AuctionBidSubmitted(
        bytes32 indexed auctionHash,
        address indexed bidder,
        uint256 amount,
        uint256 timestamp
    );
    event AuctionFinalized(
        bytes32 indexed auctionHash,
        address indexed winner,
        uint256 amount
    );
    event CancelOrder(
        bytes32 indexed orderHash,
        address indexed maker,
        uint256 orderItemIndex
    );
    event OrderMatched(
        bytes32 indexed orderHash,
        address indexed maker,
        address indexed taker,
        uint256 fillAmount
    );
    event FeeRecipientUpdated(
        address indexed oldRecipient,
        address indexed newRecipient
    );
    event AssetTransferAgentUpdated(
        address indexed oldAgent,
        address indexed newAgent
    );
    event AuctionVaultUpdated(
        address indexed oldAuctionVault,
        address indexed newAuctionVault
    );
    event FeeBpsUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event EmergencyWithdrawal(address indexed recipient, uint256 amount);
    event MarketplacePaused(address indexed operator);
    event MarketplaceUnpaused(address indexed operator);

    /**
     * @notice Contract constructor
     * @param _feeRecipient Address that receives marketplace fees
     * @param _assetTransferAgent Address of the asset transfer agent contract
     * @param _feeBps Fee basis points (e.g., 250 = 2.5%)
     */
    constructor(
        address _feeRecipient,
        address _assetTransferAgent,
        address _auctionVault,
        uint256 _feeBps
    ) Validator("LayerGMarketPlace", "1") {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(
            _assetTransferAgent != address(0),
            "Invalid asset transfer agent"
        );
        require(_auctionVault != address(0), "Invalid auction vault");
        require(_feeBps <= MAX_FEE_BPS, "Invalid fee BPS");

        feeRecipient = _feeRecipient;
        assetTransferAgent = _assetTransferAgent;
        feeBps = _feeBps;
        auctionVault = _auctionVault;
    }

    /**
     * @notice Checks if an order item is fully filled
     * @param order The order to check
     * @param orderItemIndex The index of the item within the order
     * @return True if the order item is fully filled
     */
    function isOrderFullyFilled(
        LibOrder.Order calldata order,
        uint256 orderItemIndex
    ) public view returns (bool) {
        return
            orderFillAmount[LibOrder.hash(order)][orderItemIndex] >=
            order.items[orderItemIndex].makeAsset.assetAmount;
    }

    /**
     * @notice Checks if an order item is cancelled
     * @param order The order to check
     * @param orderItemIndex The index of the item within the order
     * @return True if the order item is cancelled
     */
    function isOrderCancelled(
        LibOrder.Order calldata order,
        uint256 orderItemIndex
    ) public view returns (bool) {
        return cancelledOrders[LibOrder.hash(order)][orderItemIndex];
    }

    /**
     * @notice Updates the fee recipient address
     * @param _feeRecipient New fee recipient address
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        address oldRecipient = feeRecipient;
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(oldRecipient, _feeRecipient);
    }

    /**
     * @notice Updates the asset transfer agent address
     * @param _agent New asset transfer agent address
     */
    function setAssetTransferAgent(address _agent) external onlyOwner {
        require(_agent != address(0), "Invalid asset transfer agent");
        address oldAgent = assetTransferAgent;
        assetTransferAgent = _agent;
        emit AssetTransferAgentUpdated(oldAgent, _agent);
    }

    /**
     * @notice Updates the auction vault address
     * @param _auctionVault New auction vault address
     */
    function setAuctionVault(address _auctionVault) external onlyOwner {
        require(_auctionVault != address(0), "Invalid auction vault");
        address oldAuctionVault = auctionVault;
        auctionVault = _auctionVault;
        emit AuctionVaultUpdated(oldAuctionVault, _auctionVault);
    }

    /**
     * @notice Updates the fee basis points
     * @param _feeBps New fee basis points
     */
    function setFeeBps(uint256 _feeBps) external onlyOwner {
        require(_feeBps <= MAX_FEE_BPS, "Invalid fee BPS");
        uint256 oldFeeBps = feeBps;
        feeBps = _feeBps;
        emit FeeBpsUpdated(oldFeeBps, _feeBps);
    }

    /**
     * @notice Pauses the marketplace
     */
    function pause() external onlyOwner {
        _pause();
        emit MarketplacePaused(msg.sender);
    }

    /**
     * @notice Unpauses the marketplace
     */
    function unpause() external onlyOwner {
        _unpause();
        emit MarketplaceUnpaused(msg.sender);
    }

    /**
     * @notice Cancels an order item
     * @param order The order to cancel
     * @param orderItemIndex The index of the item within the order
     */
    function cancelOrder(
        LibOrder.Order calldata order,
        uint256 orderItemIndex
    ) external nonReentrant whenNotPaused {
        bytes32 orderHash = hashOrder(order);
        validateOrderSigner(order);
        require(msg.sender == order.maker, "Only maker can cancel");
        require(
            !isOrderFullyFilled(order, orderItemIndex),
            "Order already filled"
        );
        require(
            !isOrderCancelled(order, orderItemIndex),
            "Order already cancelled"
        );

        cancelledOrders[orderHash][orderItemIndex] = true;
        emit CancelOrder(orderHash, order.maker, orderItemIndex);
    }

    /**
     * @notice Matches a maker order with a taker order
     * @param makerOrder The maker's order
     * @param takerOrder The taker's order
     * @param orderItemIndex The index of the item within the maker's order
     * @param proof Merkle proof for bulk orders
     */
    function matchOrders(
        LibOrder.Order calldata makerOrder,
        LibOrder.Order calldata takerOrder,
        uint256 orderItemIndex,
        bytes32[] calldata proof
    ) external payable nonReentrant whenNotPaused {
        LibOrder.OrderItem calldata makerOrderItem = makerOrder.items[
            orderItemIndex
        ];
        LibOrder.OrderItem calldata takerOrderItem = takerOrder.items[0];

        _validate(makerOrder, takerOrder, orderItemIndex);
        if (makerOrder.orderType == LibOrder.OrderType.BULK) {
            validateBulkOrderItem(makerOrderItem, makerOrder.root, proof);
        }

        bytes32 makerOrderHash = LibOrder.hash(makerOrder);
        uint256 fillAmount = takerOrderItem.takeAsset.assetAmount;

        _fillOrder(
            makerOrderHash,
            fillAmount,
            makerOrderItem.makeAsset.assetAmount,
            orderItemIndex
        );

        address maker = makerOrder.maker;
        address taker = takerOrder.maker;

        LibAsset.Asset memory makeAsset = LibAsset.Asset(
            makerOrderItem.makeAsset.assetType,
            makerOrderItem.makeAsset.contractAddress,
            makerOrderItem.makeAsset.assetId,
            fillAmount
        );

        LibAsset.Asset memory takeAsset = LibAsset.Asset(
            makerOrderItem.takeAsset.assetType,
            makerOrderItem.takeAsset.contractAddress,
            makerOrderItem.takeAsset.assetId,
            fillAmount
        );

        if (takeAsset.assetType == LibAsset.AssetType.NATIVE) {
            require(
                msg.value >= takeAsset.assetAmount,
                "Insufficient msg.value"
            );
        }

        _transferWithFee(taker, maker, takeAsset);
        _transferWithFee(maker, taker, makeAsset);

        emit OrderMatched(makerOrderHash, maker, taker, fillAmount);
    }

    /**
     * @notice Batch matches multiple maker orders with a taker order
     * @param makerOrders Array of maker orders
     * @param takerOrder The taker's order
     * @param orderItemIndices Array of order item indices
     * @param proofs Array of Merkle proofs for bulk orders
     */
    function batchMatchOrders(
        LibOrder.Order[] calldata makerOrders,
        LibOrder.Order calldata takerOrder,
        uint256[] calldata orderItemIndices,
        bytes32[][] calldata proofs
    ) external payable nonReentrant whenNotPaused {
        require(
            makerOrders.length == orderItemIndices.length,
            "Length mismatch"
        );
        require(makerOrders.length == proofs.length, "Proofs length mismatch");
        require(makerOrders.length > 0, "Empty orders array");

        uint256 totalNativeAmount = 0;

        for (uint256 i = 0; i < makerOrders.length; i++) {
            // Validate array elements
            require(
                address(makerOrders[i].maker) != address(0),
                "Invalid maker address"
            );
            require(
                orderItemIndices[i] < makerOrders[i].items.length,
                "Invalid item index"
            );

            LibOrder.Order calldata makerOrder = makerOrders[i];
            uint256 orderItemIndex = orderItemIndices[i];
            bytes32[] calldata proof = proofs[i];

            LibOrder.OrderItem calldata makerOrderItem = makerOrder.items[
                orderItemIndex
            ];
            LibOrder.OrderItem calldata takerOrderItem = takerOrder.items[i];

            _validate(makerOrder, takerOrder, orderItemIndex);
            if (makerOrder.orderType == LibOrder.OrderType.BULK) {
                validateBulkOrderItem(makerOrderItem, makerOrder.root, proof);
            }

            bytes32 makerOrderHash = LibOrder.hash(makerOrder);
            uint256 fillAmount = takerOrderItem.takeAsset.assetAmount;

            _fillOrder(
                makerOrderHash,
                fillAmount,
                makerOrderItem.makeAsset.assetAmount,
                orderItemIndex
            );

            address maker = makerOrder.maker;
            address taker = takerOrder.maker;

            LibAsset.Asset memory makeAsset = LibAsset.Asset(
                makerOrderItem.makeAsset.assetType,
                makerOrderItem.makeAsset.contractAddress,
                makerOrderItem.makeAsset.assetId,
                fillAmount
            );

            LibAsset.Asset memory takeAsset = LibAsset.Asset(
                makerOrderItem.takeAsset.assetType,
                makerOrderItem.takeAsset.contractAddress,
                makerOrderItem.takeAsset.assetId,
                fillAmount
            );

            if (takeAsset.assetType == LibAsset.AssetType.NATIVE) {
                totalNativeAmount += takeAsset.assetAmount;
            }

            _transferWithFee(taker, maker, takeAsset);
            _transferWithFee(maker, taker, makeAsset);

            emit OrderMatched(makerOrderHash, maker, taker, fillAmount);
        }

        if (totalNativeAmount > 0) {
            require(
                msg.value >= totalNativeAmount,
                "Insufficient total msg.value"
            );

            // Refund excess ETH
            uint256 excess = msg.value - totalNativeAmount;
            if (excess > 0) {
                (bool success, ) = payable(msg.sender).call{value: excess}("");
                require(success, "Refund failed");
            }
        }
    }

    /**
     * @notice Accepts a bid order
     * @param bidOrder The bid order
     * @param orderItemIndex The index of the item within the bid order
     * @param sellAmount The amount to sell
     */
    function acceptBid(
        LibOrder.Order calldata bidOrder,
        uint256 orderItemIndex,
        uint256 sellAmount
    ) external nonReentrant whenNotPaused {
        require(
            bidOrder.orderType == LibOrder.OrderType.BID,
            "Not a bid order"
        );

        bytes32 orderHash = LibOrder.hash(bidOrder);
        validateOrderSigner(bidOrder);

        LibOrder.OrderItem memory bidOrderItem = bidOrder.items[orderItemIndex];
        uint256 remaining = bidOrderItem.makeAsset.assetAmount -
            orderFillAmount[orderHash][orderItemIndex];
        require(
            sellAmount > 0 && sellAmount <= remaining,
            "Invalid sell amount"
        );

        orderFillAmount[orderHash][orderItemIndex] += sellAmount;

        address bidder = bidOrder.maker;
        address seller = msg.sender;

        require(bidder != address(0), "Invalid bidder address");
        require(seller != address(0), "Invalid seller address");

        LibAsset.Asset memory makeAsset = LibAsset.Asset(
            bidOrderItem.makeAsset.assetType,
            bidOrderItem.makeAsset.contractAddress,
            bidOrderItem.makeAsset.assetId,
            sellAmount
        );

        LibAsset.Asset memory takeAsset = LibAsset.Asset(
            bidOrderItem.takeAsset.assetType,
            bidOrderItem.takeAsset.contractAddress,
            bidOrderItem.takeAsset.assetId,
            sellAmount
        );

        _transferWithFee(bidder, seller, makeAsset);
        _transferWithFee(seller, bidder, takeAsset);

        emit OrderMatched(orderHash, bidder, seller, sellAmount);
    }

    /**
     * @notice Accept a collection bid order (only support ERC721 collection)
     * @param bid bid order to accept
     * @param tokenId tokenId to accept (token id of the NFT, NFT should be in the same collection as the bid)
     */
    function acceptCollectionBid(
        LibCollectionBid.CollectionBid calldata bid,
        uint256 tokenId
    ) external nonReentrant {
        LibAsset.Asset calldata makeAssetPerItem = bid.makeAssetPerItem;
        address bidder = bid.bidder;
        address collectionAddress = bid.collectionAddress;
        bytes calldata signature = bid.signature;

        require(_isERC721(collectionAddress), "Bid collection is not ERC721");
        require(!LibCollectionBid.isExpired(bid), "Bid expired");
        require(bid.bidder == msg.sender, "Sender is not the bidder");

        bytes32 collectionBidHash = hashCollectionBid(bid);

        // Check fulfillment cap
        require(
            collectionBidFillAmount[collectionBidHash] + 1 <= bid.maxQuantity,
            "Bid max quantity exceeded"
        );

        // Verify bid signature
        address signer = LibCollectionBid.recoverSigner(
            collectionBidHash,
            signature
        );
        require(signer == bid.bidder, "Invalid signature");

        // Update fulfilled quantity
        collectionBidFillAmount[collectionBidHash]++;

        // Calculate total price
        uint256 totalPrice = makeAssetPerItem.assetAmount;

        // Transfer token from bidder to msg.sender, nft from msg.sender to bidder
        LibAsset.Asset memory makeAsset = LibAsset.Asset({
            assetType: LibAsset.AssetType.ERC721,
            contractAddress: bid.collectionAddress,
            assetId: tokenId,
            assetAmount: 1
        });
        LibAsset.Asset memory takeAsset = LibAsset.Asset({
            assetType: makeAssetPerItem.assetType,
            contractAddress: makeAssetPerItem.contractAddress,
            assetId: makeAssetPerItem.assetId,
            assetAmount: totalPrice
        });

        _transferWithFee(bidder, msg.sender, takeAsset);
        _transferWithFee(msg.sender, bidder, makeAsset);

        emit OrderMatched(collectionBidHash, bidder, msg.sender, totalPrice);
    }

    /**
     * @notice Submits a bid for an auction
     * @param auction The auction to bid on
     */
    function submitAuctionBid(
        LibAuction.Auction calldata auction
    ) external payable nonReentrant whenNotPaused {
        bytes32 auctionHash = LibAuction.hash(auction);

        // Validate auction parameters
        require(auction.maker != address(0), "Invalid auction maker");
        require(msg.sender != address(0), "Invalid bidder address");
        require(msg.sender != auction.maker, "Maker cannot bid on own auction");
        require(block.timestamp >= auction.startTime, "Auction not started");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(
            auction.endTime > auction.startTime,
            "Invalid auction duration"
        );
        require(
            auction.endTime - auction.startTime >= MIN_AUCTION_DURATION,
            "Auction too short"
        );
        require(
            auction.endTime - auction.startTime <= MAX_AUCTION_DURATION,
            "Auction too long"
        );
        require(!_isFinalized(auctionHash), "Auction already finalized");
        validateAuctionSigner(auction);
        require(msg.value >= auction.startPrice, "Bid below start price");

        // Verify that the auction asset exists and is owned by maker
        _verifyAssetOwnership(auction.maker, auction.asset);

        LibAuction.Bid storage current = highestBids[auctionHash];

        // Apply minimum bid increment logic
        if (current.amount > 0) {
            uint256 minIncrease = (current.amount * MIN_BID_INCREMENT_BPS) /
                MAX_FEE_BPS;
            uint256 minBid = current.amount + minIncrease;
            require(msg.value >= minBid, "Bid increment too small");
        }

        // Return previous bid first to prevent reentrancy attack vectors
        address previousBidder = current.bidder;
        uint256 previousAmount = current.amount;

        if (previousAmount > 0) {
            IAuctionVault(auctionVault).refund(auctionHash, previousBidder);
        }

        // Deposit new bid to auction vault
        IAuctionVault(auctionVault).deposit{value: msg.value}(
            auctionHash,
            auction.maker,
            msg.sender,
            msg.value
        );

        // Update state after external calls
        highestBids[auctionHash] = LibAuction.Bid({
            bidder: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        });

        emit AuctionBidSubmitted(
            auctionHash,
            msg.sender,
            msg.value,
            block.timestamp
        );

        // Auto-finalize if buy now price is reached
        if (auction.buyNowPrice > 0 && msg.value >= auction.buyNowPrice) {
            _finalizeAuction(auction, auctionHash);
        }
    }

    /**
     * @notice Finalizes an auction
     * @param auction The auction to finalize
     * @param signature The maker's signature
     */
    function finalizeAuction(
        LibAuction.Auction calldata auction,
        bytes calldata signature
    ) external nonReentrant whenNotPaused {
        bytes32 auctionHash = hashAuction(auction);
        require(!_isFinalized(auctionHash), "Already finalized");
        require(block.timestamp >= auction.endTime, "Auction not ended");
        require(
            _verifyAuctionSignature(auction, signature),
            "Invalid signature"
        );
        require(auction.maker != address(0), "Invalid auction maker");

        LibAuction.Bid memory winningBid = highestBids[auctionHash];
        require(winningBid.amount > 0, "No bids placed");
        require(winningBid.bidder != address(0), "Invalid winning bidder");

        // Verify asset ownership
        _verifyAssetOwnership(auction.maker, auction.asset);

        _finalizeAuction(auction, auctionHash);
    }

    /**
     * @notice Emergency withdraw contract funds to owner
     * @dev Only called in emergencies
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Emergency withdrawal failed");

        emit EmergencyWithdrawal(owner(), balance);
    }

    /**
     * @notice Internal function to finalize an auction
     * @param auction The auction to finalize
     * @param auctionHash The hash of the auction
     */
    function _finalizeAuction(
        LibAuction.Auction memory auction,
        bytes32 auctionHash
    ) internal {
        // Update state before external calls
        auctionFinalized[auctionHash] = true;

        LibAuction.Bid memory winningBid = highestBids[auctionHash];
        require(winningBid.amount > 0, "No bids placed");
        require(winningBid.bidder != address(0), "Invalid winning bidder");

        // Transfer asset first
        if (auction.asset.assetType == LibAsset.AssetType.ERC721) {
            IAssetTransferAgent(assetTransferAgent).transferERC721(
                auction.asset.contractAddress,
                auction.maker,
                winningBid.bidder,
                auction.asset.assetId
            );
        } else if (auction.asset.assetType == LibAsset.AssetType.ERC1155) {
            IAssetTransferAgent(assetTransferAgent).transferERC1155(
                auction.asset.contractAddress,
                auction.maker,
                winningBid.bidder,
                auction.asset.assetId,
                auction.asset.assetAmount,
                ""
            );
        } else {
            revert("Unsupported asset type");
        }

        // Calculate fee
        uint256 feeAmount = (winningBid.amount * feeBps) / MAX_FEE_BPS;
        uint256 amountAfterFee = winningBid.amount - feeAmount;

        // Transfer funds directly
        if (feeAmount > 0) {
            (bool feeSent, ) = payable(feeRecipient).call{value: feeAmount}("");
            require(feeSent, "Fee transfer failed");
        }
        (bool sent, ) = payable(auction.maker).call{value: amountAfterFee}("");
        require(sent, "Payment transfer failed");

        emit AuctionFinalized(
            auctionHash,
            winningBid.bidder,
            winningBid.amount
        );
    }

    /**
     * @notice Checks if an auction is finalized
     * @param auctionHash The hash of the auction
     * @return True if the auction is finalized
     */
    function _isFinalized(bytes32 auctionHash) internal view returns (bool) {
        return auctionFinalized[auctionHash];
    }

    /**
     * @notice Verifies an auction signature
     * @param auction The auction
     * @param signature The signature to verify
     * @return True if the signature is valid
     */
    function _verifyAuctionSignature(
        LibAuction.Auction calldata auction,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 digest = hashAuction(auction);
        address signer = digest.recover(signature);
        return signer == auction.maker;
    }

    /**
     * @notice Fill an order
     * @param orderHash The hash of the order
     * @param fillAmount The amount to fill
     * @param totalAmount The total amount of the order
     * @param orderItemIndex The index of the item within the order
     */
    function _fillOrder(
        bytes32 orderHash,
        uint256 fillAmount,
        uint256 totalAmount,
        uint256 orderItemIndex
    ) internal {
        uint256 filled = orderFillAmount[orderHash][orderItemIndex];
        require(
            fillAmount > 0 && filled + fillAmount <= totalAmount,
            "Invalid fill"
        );
        orderFillAmount[orderHash][orderItemIndex] = filled + fillAmount;
    }

    /**
     * @notice Transfer an asset with fee
     * @param from The sender address
     * @param to The recipient address
     * @param asset The asset to transfer
     */
    function _transferWithFee(
        address from,
        address to,
        LibAsset.Asset memory asset
    ) internal {
        require(feeRecipient != address(0), "Fee recipient not set");
        require(assetTransferAgent != address(0), "Transfer agent not set");
        require(to != address(0), "Invalid recipient");

        uint256 feeAmount = (asset.assetAmount * feeBps) / MAX_FEE_BPS;
        uint256 amountAfterFee = asset.assetAmount - feeAmount;

        if (asset.assetType == LibAsset.AssetType.NATIVE) {
            // Handle Native ETH transfers directly
            require(msg.value >= asset.assetAmount, "Insufficient msg.value");
            if (feeAmount > 0) {
                (bool feeSent, ) = payable(feeRecipient).call{value: feeAmount}(
                    ""
                );
                require(feeSent, "Fee transfer failed");
            }
            (bool sent, ) = payable(to).call{value: amountAfterFee}("");
            require(sent, "Native transfer failed");
        } else if (asset.assetType == LibAsset.AssetType.ERC20) {
            // Handle ERC20 transfers
            if (feeAmount > 0) {
                IAssetTransferAgent(assetTransferAgent).transferERC20(
                    asset.contractAddress,
                    from,
                    feeRecipient,
                    feeAmount
                );
            }
            IAssetTransferAgent(assetTransferAgent).transferERC20(
                asset.contractAddress,
                from,
                to,
                amountAfterFee
            );
        } else if (asset.assetType == LibAsset.AssetType.ERC721) {
            // Handle ERC721 transfers
            IAssetTransferAgent(assetTransferAgent).transferERC721(
                asset.contractAddress,
                from,
                to,
                asset.assetId
            );
        } else if (asset.assetType == LibAsset.AssetType.ERC1155) {
            // Handle ERC1155 transfers
            IAssetTransferAgent(assetTransferAgent).transferERC1155(
                asset.contractAddress,
                from,
                to,
                asset.assetId,
                asset.assetAmount,
                ""
            );
        } else {
            revert("Unsupported asset type");
        }
    }

    /**
     * @notice Validate order matching
     * @param makerOrder The maker's order
     * @param takerOrder The taker's order
     * @param orderItemIndex The index of the item within the maker's order
     */
    function _validate(
        LibOrder.Order calldata makerOrder,
        LibOrder.Order calldata takerOrder,
        uint256 orderItemIndex
    ) internal view {
        validateOrderSigner(makerOrder);
        validateIfMatchedBothSide(makerOrder, takerOrder, orderItemIndex);
        require(msg.sender == takerOrder.maker, "Sender is not taker");
        require(
            !isOrderFullyFilled(makerOrder, orderItemIndex),
            "Maker order filled"
        );
        require(
            !isOrderCancelled(makerOrder, orderItemIndex),
            "Maker order cancelled"
        );
        require(
            !LibOrder.isExpired(makerOrder, orderItemIndex),
            "Maker order expired"
        );
    }

    /**
     * @notice Verifies that an address owns an asset
     * @param assetOwner The address to check
     * @param asset The asset to verify
     */
    function _verifyAssetOwnership(
        address assetOwner,
        LibAsset.Asset memory asset
    ) internal view {
        require(assetOwner != address(0), "Invalid owner");

        if (asset.assetType == LibAsset.AssetType.ERC721) {
            require(
                IERC721(asset.contractAddress).ownerOf(asset.assetId) ==
                    assetOwner,
                "Not ERC721 owner"
            );
        } else if (asset.assetType == LibAsset.AssetType.ERC1155) {
            require(
                IERC1155(asset.contractAddress).balanceOf(
                    assetOwner,
                    asset.assetId
                ) >= asset.assetAmount,
                "Insufficient ERC1155 balance"
            );
        } else if (asset.assetType == LibAsset.AssetType.ERC20) {
            require(
                IERC20(asset.contractAddress).balanceOf(assetOwner) ==
                    asset.assetAmount,
                "Insufficient ERC20 balance"
            );
        } else if (asset.assetType == LibAsset.AssetType.NATIVE) {
            require(
                assetOwner.balance >= asset.assetAmount,
                "Insufficient native balance"
            );
        } else {
            revert("Unsupported asset type");
        }
    }

    /**
     * @notice Verifies that an collection is ERC721 or not
     * @param collection The address of the collection
     */
    function _isERC721(address collection) internal view returns (bool) {
        try
            IERC165(collection).supportsInterface(type(IERC721).interfaceId)
        returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }

    /**
     * @notice Verifies that an collection is ERC1155 or not
     * @param collection The address of the collection
     */
    function _isERC1155(address collection) internal view returns (bool) {
        try
            IERC165(collection).supportsInterface(type(IERC1155).interfaceId)
        returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }

    /**
     * @notice Function to receive ETH
     */
    receive() external payable {
        // Default ETH receiving function
    }
}
