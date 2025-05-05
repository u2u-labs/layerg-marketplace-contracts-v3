// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAssetTransferAgent.sol";

contract AssetTransferAgent is IAssetTransferAgent, Ownable {
    using SafeERC20 for IERC20;

    address public marketplace;

    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "Only marketplace can call");
        _;
    }

    constructor() {}

    function setMarketplace(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "Invalid marketplace address");
        marketplace = _marketplace;
    }

    function transferERC20(
        address token,
        address from,
        address to,
        uint256 amount
    ) external override onlyMarketplace {
        IERC20(token).safeTransferFrom(from, to, amount);
        emit ERC20Transferred(token, from, to, amount);
    }

    function transferERC721(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external override onlyMarketplace {
        IERC721(token).safeTransferFrom(from, to, tokenId);
        emit ERC721Transferred(token, from, to, tokenId);
    }

    function transferERC1155(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override onlyMarketplace {
        IERC1155(token).safeTransferFrom(from, to, id, amount, data);
        emit ERC1155Transferred(token, from, to, id, amount);
    }
}
