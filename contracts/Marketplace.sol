// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/LibOrder.sol";
import "./libraries/LibAsset.sol";
import "./interfaces/IAssetTransferAgent.sol";
import "./OrderValidator.sol";

contract Marketplace is ReentrancyGuard, Ownable, OrderValidator {
    uint256 public constant MAX_FEE_BPS = 10000;
    address public feeRecipient;
    address public assetTransferAgent;
    uint256 public feeBps;

    mapping(bytes32 => mapping(uint256 => uint256)) public orderFillAmount;
    mapping(bytes32 => mapping(uint256 => bool)) private cancelledOrders;

    event CancelOrder(bytes32 indexed orderHash);
    event OrderMatched(
        bytes32 indexed orderHash,
        address indexed maker,
        address indexed taker,
        uint256 fillAmount
    );

    constructor(
        address _feeRecipient,
        address _assetTransferAgent,
        uint256 _feeBps
    ) OrderValidator("LayerGMarketPlace", "1") {
        feeRecipient = _feeRecipient;
        assetTransferAgent = _assetTransferAgent;
        require(_feeBps >= 0 && _feeBps <= MAX_FEE_BPS, "Invalid fee BPS");
        feeBps = _feeBps;
    }

    function isOrderFullyFilled(
        LibOrder.Order calldata order,
        uint256 orderItemIndex
    ) public view returns (bool) {
        return
            orderFillAmount[LibOrder.hash(order)][orderItemIndex] >=
            order.items[orderItemIndex].makeAsset.assetAmount;
    }

    function isOrderCancelled(
        LibOrder.Order calldata order,
        uint256 orderItemIndex
    ) public view returns (bool) {
        return cancelledOrders[LibOrder.hash(order)][orderItemIndex];
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    function setAssetTransferAgent(address _agent) external onlyOwner {
        require(_agent != address(0), "Invalid asset transfer agent");
        assetTransferAgent = _agent;
    }

    function setFeeBps(uint256 _feeBps) external onlyOwner {
        require(_feeBps >= 0 && _feeBps <= MAX_FEE_BPS, "Invalid fee BPS");
        feeBps = _feeBps;
    }

    function cancelOrder(
        LibOrder.Order calldata order,
        uint256 orderItemIndex
    ) external nonReentrant {
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
        emit CancelOrder(orderHash);
    }

    function matchOrders(
        LibOrder.Order calldata makerOrder,
        LibOrder.Order calldata takerOrder,
        uint256 orderItemIndex,
        bytes32[] calldata proof
    ) external payable nonReentrant {
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

        _transferWithFee(taker, maker, takeAsset);
        _transferWithFee(maker, taker, makeAsset);

        emit OrderMatched(makerOrderHash, maker, taker, fillAmount);
    }

    function batchMatchOrders(
        LibOrder.Order[] calldata makerOrders,
        LibOrder.Order calldata takerOrder,
        uint256[] calldata orderItemIndices,
        bytes32[][] calldata proofs
    ) external payable nonReentrant {
        require(
            makerOrders.length == orderItemIndices.length,
            "Length mismatch"
        );
        require(makerOrders.length == proofs.length, "Proofs length mismatch");

        uint256 totalNativeAmount = 0;

        for (uint256 i = 0; i < makerOrders.length; i++) {
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

            // Accumulate native payment
            if (takeAsset.assetType == LibAsset.AssetType.NATIVE) {
                totalNativeAmount += takeAsset.assetAmount;
            }

            _transferWithFee(taker, maker, takeAsset);
            _transferWithFee(maker, taker, makeAsset);

            emit OrderMatched(makerOrderHash, maker, taker, fillAmount);
        }

        // Check that enough ETH was sent
        if (totalNativeAmount > 0) {
            require(
                msg.value >= totalNativeAmount,
                "Insufficient total msg.value"
            );
        }
    }

    function acceptBid(
        LibOrder.Order calldata bidOrder,
        uint256 orderItemIndex,
        uint256 sellAmount
    ) external payable nonReentrant {
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

    function _transferWithFee(
        address from,
        address to,
        LibAsset.Asset memory asset
    ) internal {
        require(feeRecipient != address(0), "Fee recipient not set");
        require(assetTransferAgent != address(0), "Transfer agent not set");
        if (asset.assetType == LibAsset.AssetType.NATIVE) {
            uint256 feeAmount = (asset.assetAmount * feeBps) / 10000;
            uint256 amountAfterFee = asset.assetAmount - feeAmount;
            require(msg.value >= asset.assetAmount, "Insufficient msg.value");
            if (feeAmount > 0) {
                (bool feeSent, ) = feeRecipient.call{value: feeAmount}("");
                require(feeSent, "Fee transfer failed");
            }
            (bool sent, ) = to.call{value: amountAfterFee}("");
            require(sent, "Native transfer failed");
        } else if (asset.assetType == LibAsset.AssetType.ERC20) {
            uint256 feeAmount = (asset.assetAmount * feeBps) / 10000;
            uint256 amountAfterFee = asset.assetAmount - feeAmount;
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
            IAssetTransferAgent(assetTransferAgent).transferERC721(
                asset.contractAddress,
                from,
                to,
                asset.assetId
            );
        } else if (asset.assetType == LibAsset.AssetType.ERC1155) {
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

    function _validate(
        LibOrder.Order calldata makerOrder,
        LibOrder.Order calldata takerOrder,
        uint256 orderItemIndex
    ) internal view {
        validateOrderSigner(makerOrder);
        validateIfMatchedBothSide(makerOrder, takerOrder, orderItemIndex);
        require(msg.sender == takerOrder.maker, "Sender is not taker");

        // Validate if orders are fully filled
        require(
            !isOrderFullyFilled(makerOrder, orderItemIndex),
            "Maker order filled"
        );
        // Validate if orders are cancelled
        require(
            !isOrderCancelled(makerOrder, orderItemIndex),
            "Maker order cancelled"
        );
        // Validate if orders are expired
        require(
            !LibOrder.isOrderExpired(makerOrder, orderItemIndex),
            "Maker order expired"
        );
    }
}
