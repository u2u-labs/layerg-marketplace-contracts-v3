// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./LibAsset.sol";

/**
 * @title LibCollectionBid
 * @notice Library for collection bid operations and data structures
 * @dev Handles hashing, verification, and utility functions for collection bids
 */
library LibCollectionBid {
    using ECDSA for bytes32;

    bytes32 private constant COLLECTION_BID_TYPEHASH =
        keccak256(
            "CollectionBid(address bidder,Asset makeAssetPerItem,address collectionAddress,uint256 maxQuantity,uint256 start,uint256 end,uint256 salt)Asset(uint8 assetType,address contractAddress,uint256 assetId,uint256 assetAmount)"
        );

    struct CollectionBid {
        address bidder;
        LibAsset.Asset makeAssetPerItem;
        address collectionAddress;
        uint256 maxQuantity;
        uint256 start;
        uint256 end;
        uint256 salt;
        bytes signature;
    }

    function hash(CollectionBid calldata bid) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    COLLECTION_BID_TYPEHASH,
                    bid.bidder,
                    LibAsset.hash(bid.makeAssetPerItem),
                    bid.collectionAddress,
                    bid.maxQuantity,
                    bid.start,
                    bid.end,
                    bid.salt
                )
            );
    }

    function recoverSigner(
        bytes32 orderHash,
        bytes memory signature
    ) internal pure returns (address) {
        return ECDSA.recover(orderHash, signature);
    }

    function isExpired(CollectionBid memory bid) internal view returns (bool) {
        return block.timestamp > bid.end;
    }
}
