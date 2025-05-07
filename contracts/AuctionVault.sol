// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAuctionVault.sol";

/**
 * @title AuctionVault
 * @notice Auction's vault contract for users to deposit funds for auction participation
 * @dev Handles deposits, refunds (ERC20, native token)
 */
contract AuctionVault is Ownable, ReentrancyGuard, Pausable, IAuctionVault {
    using SafeERC20 for IERC20;

    address public operator; // address of the operator (in this case the marketplace)
    uint256 public emergencyWithdrawalDelay = 30 days;
    struct Deposit {
        address bidder;
        address token; // address(0) for native
        uint256 amount;
        bool refunded;
        uint256 depositTime;
    }

    mapping(address => mapping(bytes32 => Deposit)) public deposits; // userAddress => (auctionHash => Deposit)

    // Events
    event Deposited(
        bytes32 indexed auctionHash,
        address indexed bidder,
        uint256 amount,
        address token
    );
    event Refunded(
        bytes32 indexed auctionHash,
        address indexed bidder,
        uint256 amount,
        address token
    );
    event Finalized(
        bytes32 indexed auctionHash,
        address indexed seller,
        uint256 amount,
        address token
    );
    event operatorUpdated(address oldoperator, address newoperator);
    event EmergencyWithdrawal(
        bytes32 indexed auctionHash,
        address indexed bidder,
        uint256 amount,
        address token
    );

    // Modifiers
    modifier onlyOperator() {
        require(msg.sender == operator, "Not operator");
        _;
    }

    constructor(address _operator) {
        require(_operator != address(0), "Invalid operator");
        operator = _operator;
    }

    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Invalid address");
        address oldoperator = operator;
        operator = _operator;
        emit operatorUpdated(oldoperator, _operator);
    }

    function setEmergencyWithdrawalDelay(uint256 _delay) external onlyOwner {
        emergencyWithdrawalDelay = _delay;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function hasDeposit(
        address bidder,
        bytes32 auctionHash
    ) external view returns (bool) {
        return
            deposits[bidder][auctionHash].amount > 0 &&
            !deposits[bidder][auctionHash].refunded;
    }

    function getDeposit(
        address bidder,
        bytes32 auctionHash
    )
        external
        view
        returns (
            address _bidder,
            address _token,
            uint256 _amount,
            bool _refunded,
            uint256 _depositTime
        )
    {
        Deposit storage dep = deposits[bidder][auctionHash];
        return (
            dep.bidder,
            dep.token,
            dep.amount,
            dep.refunded,
            dep.depositTime
        );
    }

    /**
     * @notice Deposit funds for auction participation (called by operator)
     * @param auctionHash Hash of auction
     * @param token Token's address to deposit (address(0) for native)
     * @param amount Token's amount to deposit
     */
    function deposit(
        bytes32 auctionHash,
        address bidder,
        address token,
        uint256 amount
    ) external payable onlyOperator nonReentrant whenNotPaused {
        require(bidder != address(0), "Invalid bidder");
        require(amount > 0, "Zero amount");
        require(deposits[bidder][auctionHash].amount == 0, "Deposit exists");

        if (token == address(0)) {
            require(msg.value == amount, "Incorrect msg.value");
        } else {
            IERC20(token).safeTransferFrom(bidder, address(this), amount);
        }

        deposits[bidder][auctionHash] = Deposit({
            bidder: bidder,
            token: token,
            amount: amount,
            refunded: false,
            depositTime: block.timestamp
        });

        emit Deposited(auctionHash, bidder, amount, token);
    }

    /**
     * @notice Refunds a deposit for a bidder in an auction (called by operator)
     * @param auctionHash Hash of auction
     * @param bidder Bidder's address
     */
    function refund(
        bytes32 auctionHash,
        address bidder
    ) external onlyOperator nonReentrant {
        Deposit storage dep = deposits[bidder][auctionHash];
        require(dep.amount > 0, "No deposit found");
        require(!dep.refunded, "Already refunded");

        dep.refunded = true;

        uint256 refundAmount = dep.amount;
        address refundToken = dep.token;

        // Then perform the transfer
        if (refundToken == address(0)) {
            payable(dep.bidder).transfer(refundAmount);
        } else {
            IERC20(refundToken).safeTransfer(dep.bidder, refundAmount);
        }

        emit Refunded(auctionHash, dep.bidder, refundAmount, refundToken);
    }

    /**
     * @notice Finalizes a deposit for a bidder in an auction (transfer bidder's deposit to seller, called by operator)
     * @param auctionHash Hash of auction
     * @param seller Seller's address
     * @param bidder Bidder's address
     */
    function finalize(
        bytes32 auctionHash,
        address seller,
        address bidder
    ) external onlyOperator nonReentrant {
        Deposit storage dep = deposits[bidder][auctionHash];
        require(dep.amount > 0, "No deposit found");
        require(!dep.refunded, "Already refunded");

        dep.refunded = true;

        uint256 sellerAmount = dep.amount;
        address token = dep.token;

        // Perform transfers
        if (token == address(0)) {
            payable(seller).transfer(sellerAmount);
        } else {
            IERC20 tokenContract = IERC20(token);
            tokenContract.safeTransfer(seller, sellerAmount);
        }

        emit Finalized(auctionHash, seller, sellerAmount, token);
    }

    /**
     * @notice Emergency withdraw for a bidder in an auction (called by bidder)
     * @param auctionHash Hash of auction
     */
    function emergencyWithdraw(bytes32 auctionHash) external nonReentrant {
        Deposit storage dep = deposits[msg.sender][auctionHash];
        require(dep.amount > 0, "No deposit found");
        require(!dep.refunded, "Already refunded");
        require(
            block.timestamp > dep.depositTime + emergencyWithdrawalDelay,
            "Withdrawal delay not met"
        );

        dep.refunded = true;

        uint256 withdrawAmount = dep.amount;
        address token = dep.token;

        // Perform the transfer
        if (token == address(0)) {
            payable(msg.sender).transfer(withdrawAmount);
        } else {
            IERC20(token).safeTransfer(msg.sender, withdrawAmount);
        }

        emit EmergencyWithdrawal(
            auctionHash,
            msg.sender,
            withdrawAmount,
            token
        );
    }
}
