    // SPDX-License-Identifier: MIT

    pragma solidity ^0.8.20;

    import "@openzeppelin/contracts/interfaces/IERC1271.sol";
    import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
    import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
    import "./libraries/LibOrder.sol";
    import "./libraries/LibAsset.sol";
    import "./libraries/LibAuction.sol";
    import "./libraries/LibCollectionBid.sol";
    import "./libraries/MerkleProof.sol";

    abstract contract Validator is EIP712 {
        using ECDSA for bytes32;

        bytes4 internal constant MAGICVALUE = 0x1626ba7e;

        constructor(
            string memory name,
            string memory version
        ) EIP712(name, version) {}

        function hashOrder(
            LibOrder.Order calldata order
        ) internal view returns (bytes32) {
            bytes32 orderHash = LibOrder.hash(order);
            bytes32 hash = _hashTypedDataV4(orderHash);
            return hash;
        }

        function hashAuction(
            LibAuction.Auction calldata auction
        ) internal view returns (bytes32) {
            bytes32 auctionHash = LibAuction.hash(auction);
            bytes32 hash = _hashTypedDataV4(auctionHash);
            return hash;
        }

        function hashCollectionBid(
            LibCollectionBid.CollectionBid calldata bid
        ) internal view returns (bytes32) {
            bytes32 hash = _hashTypedDataV4(LibCollectionBid.hash(bid));
            return hash;
        }

        function validateBulkOrderItem(
            LibOrder.OrderItem calldata orderItem,
            bytes32 root,
            bytes32[] calldata proof
        ) internal pure {
            // Hash the entire maker order using LibOrder.hash() to generate the Merkle leaf
            bytes32 leaf = LibOrder.hashOrderItem(orderItem);
            // Verify the Merkle proof
            require(verifyMerkleProof(proof, root, leaf), "Invalid Merkle proof");
        }

        function verifyMerkleProof(
            bytes32[] calldata proof,
            bytes32 root,
            bytes32 leaf
        ) public pure returns (bool) {
            return MerkleProof.verify(proof, root, leaf);
        }

        function validateIfMatchedBothSide(
            LibOrder.Order calldata makerOrder,
            LibOrder.Order calldata takerOrder,
            uint256 index
        ) internal pure {
            LibOrder.OrderItem calldata makerItem = makerOrder.items[index];
            LibOrder.OrderItem calldata takerItem = takerOrder.items[0];

            require(makerOrder.maker == takerOrder.taker, "Taker must match maker");

            // Match metadata, ignore amount (it’s calculated at runtime)
            LibAsset.validateCompatibleAssetMetadata(
                makerItem.takeAsset,
                takerItem.makeAsset
            );
            LibAsset.validateCompatibleAssetMetadata(
                makerItem.makeAsset,
                takerItem.takeAsset
            );
        }

        /**
         * @notice Validates the order signature
         * @param order The order to validate the signer
         */
        function validateOrderSigner(LibOrder.Order calldata order) internal view {
            address maker = order.maker;
            bytes32 orderHash = hashOrder(order);
            bytes calldata signature = order.signature;
            if (maker.code.length > 0) {
                require(
                    IERC1271(maker).isValidSignature(orderHash, signature) ==
                        MAGICVALUE,
                    "contract order signature verification error"
                );
            } else {
                address signer = LibOrder.recoverSigner(orderHash, signature);
                require(
                    maker == signer,
                    "Invalid signature. Maker is not the signer"
                );
            }
        }

        function validateAuctionSigner(
            LibAuction.Auction calldata auction
        ) internal view {
            address maker = auction.maker;
            bytes32 auctionHash = hashAuction(auction);
            bytes calldata signature = auction.signature;
            if (maker.code.length > 0) {
                require(
                    IERC1271(maker).isValidSignature(auctionHash, signature) ==
                        MAGICVALUE,
                    "contract auction signature verification error"
                );
            } else {
                address signer = LibAuction.recoverSigner(auctionHash, signature);
                require(
                    maker == signer,
                    "Invalid signature. Maker is not the signer"
                );
            }
        }

        function validateCollectionBidSigner(
            LibCollectionBid.CollectionBid calldata bid
        ) internal view {
            address bidder = bid.bidder;
            bytes32 collectionBidHash = hashCollectionBid(bid);
            bytes calldata signature = bid.signature;
            if (bidder.code.length > 0) {
                require(
                    IERC1271(bidder).isValidSignature(
                        collectionBidHash,
                        signature
                    ) == MAGICVALUE,
                    "contract collection bid signature verification error"
                );
            } else {
                address signer = LibCollectionBid.recoverSigner(
                    collectionBidHash,
                    signature
                );
                require(
                    bidder == signer,
                    "Invalid signature. Maker is not the signer"
                );
            }
        }
    }
