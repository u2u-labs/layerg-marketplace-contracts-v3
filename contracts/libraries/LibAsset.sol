// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LibAsset {
    enum AssetType {
        NATIVE,
        ERC20,
        ERC1155,
        ERC721
    }

    bytes32 private constant ASSET_TYPE_HASH =
        keccak256(
            "Asset(uint8 assetType,address contractAddress,uint256 assetId,uint256 assetAmount)"
        );

    struct Asset {
        AssetType assetType;
        address contractAddress;
        uint256 assetId;
        uint256 assetAmount;
    }

    function hash(Asset calldata asset) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASSET_TYPE_HASH,
                    asset.assetType,
                    asset.contractAddress,
                    asset.assetId,
                    asset.assetAmount
                )
            );
    }

    function validateCompatibleAssetMetadata(
        Asset calldata requestedAsset,
        Asset calldata offeredAsset
    ) internal pure {
        require(
            requestedAsset.assetType == offeredAsset.assetType,
            "Asset type mismatch"
        );
        require(
            requestedAsset.contractAddress == offeredAsset.contractAddress,
            "Contract address mismatch"
        );
        require(
            requestedAsset.assetId == offeredAsset.assetId,
            "Asset ID mismatch"
        );
    }

    function validateCompatibleAssetWithAmountCap(
        Asset calldata requested,
        Asset calldata offered
    ) internal pure {
        validateCompatibleAssetMetadata(requested, offered);
        require(offered.assetAmount <= requested.assetAmount, "Amount exceeds");
    }
}
