// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./LibAsset.sol";

library LibAuction {
    bytes32 private constant AUCTION_TYPEHASH =
        keccak256(
            "Auction(address maker,Asset asset,uint256 startPrice,uint256 buyNowPrice,uint256 startTime,uint256 endTime,uint256 salt)Asset(uint8 assetType,address contractAddress,uint256 assetId,uint256 assetAmount)"
        );

    struct Auction {
        address maker;
        LibAsset.Asset asset;
        uint256 startPrice;
        uint256 buyNowPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 salt;
        bytes signature;
    }

    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }

    function hash(Auction memory auction) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    AUCTION_TYPEHASH,
                    auction.maker,
                    LibAsset.hash(auction.asset),
                    auction.startPrice,
                    auction.buyNowPrice,
                    auction.startTime,
                    auction.endTime,
                    auction.salt
                )
            );
    }

    function recoverSigner(
        bytes32 auctionHash,
        bytes memory signature
    ) internal pure returns (address) {
        return ECDSA.recover(auctionHash, signature);
    }
}
