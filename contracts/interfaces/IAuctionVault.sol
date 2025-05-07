// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IAuctionVault
/// @notice Interface for the AuctionVault contract which escrows ERC20 or native token deposits for auction bids.

interface IAuctionVault {
    /// @notice Called by operator to record a user's deposit (native or ERC20) for an auction
    /// @dev Requires msg.value if token is native (address(0)). Only callable by the operator.
    function deposit(
        bytes32 auctionHash,
        address bidder,
        address token,
        uint256 amount
    ) external payable;

    /// @notice Refunds a bidder's deposit (e.g. if they lost the auction or it was cancelled)
    /// @dev Only callable by the operator
    function refund(bytes32 auctionHash, address bidder) external;

    /// @notice Finalizes a successful auction and transfers the bid amount to the seller
    /// @dev Only callable by the operator
    function finalize(
        bytes32 auctionHash,
        address seller,
        address bidder
    ) external;
}
