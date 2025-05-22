// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./LibAsset.sol";

library LibOrder {
    using ECDSA for bytes32;

    bytes32 private constant ORDER_ITEM_TYPEHASH =
        keccak256(
            "OrderItem(Asset makeAsset,Asset takeAsset,uint256 start,uint256 end)Asset(uint8 assetType,address contractAddress,uint256 assetId,uint256 assetAmount)"
        );

    bytes32 private constant ORDER_TYPEHASH =
        keccak256(
            "Order(uint8 orderType,OrderItem[] items,address maker,address taker,bytes32 root,uint256 salt)OrderItem(Asset makeAsset,Asset takeAsset,uint256 start,uint256 end)Asset(uint8 assetType,address contractAddress,uint256 assetId,uint256 assetAmount)"
        );

    enum OrderType {
        BID,
        ASK,
        BULK
    }

    struct OrderItem {
        LibAsset.Asset makeAsset;
        LibAsset.Asset takeAsset;
        uint256 start;
        uint256 end;
    }

    struct Order {
        OrderType orderType;
        OrderItem[] items;
        address maker;
        address taker;
        bytes32 root;
        uint256 salt;
        bytes signature;
    }

    struct CollectionBid {
        address collection;
        uint256 pricePerItem;
        uint256 maxQuantity;
    }

    function hashOrderItem(
        OrderItem calldata item
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_ITEM_TYPEHASH,
                    LibAsset.hash(item.makeAsset),
                    LibAsset.hash(item.takeAsset),
                    item.start,
                    item.end
                )
            );
    }

    function hash(Order calldata order) internal pure returns (bytes32) {
        uint256 len = order.items.length;
        bytes32[] memory itemHashes = new bytes32[](len);
        for (uint256 i = 0; i < len; ) {
            itemHashes[i] = hashOrderItem(order.items[i]);
            unchecked {
                ++i;
            }
        }

        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.orderType,
                    keccak256(abi.encode(itemHashes)),
                    order.maker,
                    order.taker,
                    order.root,
                    order.salt
                )
            );
    }

    function recoverSigner(
        bytes32 orderHash,
        bytes memory signature
    ) internal pure returns (address) {
        return ECDSA.recover(orderHash, signature);
    }

    function isExpired(
        Order memory order,
        uint256 orderItemIndex
    ) internal view returns (bool) {
        return block.timestamp > order.items[orderItemIndex].end;
    }
}
