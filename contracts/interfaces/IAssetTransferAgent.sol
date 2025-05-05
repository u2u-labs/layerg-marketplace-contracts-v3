// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAssetTransferAgent {
    event ERC20Transferred(address indexed token, address indexed from, address indexed to, uint256 amount);
    event ERC721Transferred(address indexed token, address indexed from, address indexed to, uint256 tokenId);
    event ERC1155Transferred(address indexed token, address indexed from, address indexed to, uint256 tokenId, uint256 amount);
    event ERC1155BatchTransferred(address indexed token, address indexed from, address indexed to, uint256[] tokenIds, uint256[] amounts);

    function transferERC20(address token, address from, address to, uint256 amount) external;

    function transferERC721(address token, address from, address to, uint256 tokenId) external;

    function transferERC1155(address token, address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}
