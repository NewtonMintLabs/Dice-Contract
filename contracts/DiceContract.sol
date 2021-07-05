// SPDX-License-Identifier: MIT
/**
 * NFT Dice Game Contract
 */
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IBEP20.sol";

contract Dice is Context, Ownable {
    using SafeMath for uint256;

    uint256 private _feePercent;
    uint256 private _withdrawFeePercent;
    uint256 private _adminBalance;

    mapping(address => uint256) private _balanceOf;

    event DiceGame(
        uint256 gameId,
        address indexed winner,
        uint256 winnerAmount,
        uint256 feeAmount
    );
    event WithdrawBNBToUser(
        address indexed userAddress,
        uint256 withdrawAmount,
        uint256 feeAmount
    );
    event WithdrawBNBToAdmin(
        address indexed adminAddress,
        uint256 withdrawAmount
    );

    constructor() {
        _feePercent = 1000; // 10%
        _withdrawFeePercent = 100; // 1%
        _adminBalance = 0;
    }

    /**
     * @dev receive event
     */
    receive() external payable {
        address player = _msgSender();
        uint256 depositAmount = msg.value;

        _balanceOf[player] = _balanceOf[player].add(depositAmount);
    }

    /**
     * @dev Get Balance
     */
    function balanceOf(address player) public view returns (uint256) {
        return _balanceOf[player];
    }

    /**
     * @dev Get Admin Amount
     */
    function getAdminAmount() public view returns (uint256) {
        return _adminBalance;
    }

    /**
     * @dev Get Fee Amount
     */
    function getFeePercent() public view returns (uint256) {
        return _feePercent;
    }

    /**
     * @dev Set Fee Amount
     */
    function setFeePercent(uint256 feePercent) external onlyOwner {
        _feePercent = feePercent;
    }

    /**
     * @dev Get Withdraw Fee Percent
     */
    function getWithdrawFeePercent() public view returns (uint256) {
        return _withdrawFeePercent;
    }

    /**
     * @dev Set Withdraw Fee Percent
     */
    function setWithdrawFeePercent(uint256 withdrawFeePercent)
        external
        onlyOwner
    {
        _withdrawFeePercent = withdrawFeePercent;
    }

    /**
     * @dev Withdraw BNB to User
     */
    function withdrawBNBToUser(address userAddress, uint256 amount)
        external
        onlyOwner
    {
        require(
            _balanceOf[userAddress] >= amount,
            "Withdraw amount should be less than balance of player"
        );

        uint256 withdrawFeeAmount = amount.mul(_withdrawFeePercent).div(10000);
        uint256 withdrawAmount = amount.sub(withdrawFeeAmount);

        // Update Balance
        _balanceOf[userAddress] = _balanceOf[userAddress].sub(amount);

        // Update Admin Balance
        _adminBalance = _adminBalance.add(withdrawFeeAmount);

        // Send BNB From Contract to User Address
        (bool userWithdraw, ) = userAddress.call{value: withdrawAmount}("");
        require(userWithdraw, "Failed to Withdraw BNB to User.");

        // Emit Withdraw BNB to User
        emit WithdrawBNBToUser(userAddress, amount, withdrawFeeAmount);
    }

    /**
     * @dev Withdraw BNB to User
     */
    function withdrawBNBToAdmin(address adminAddress, uint256 amount)
        external
        onlyOwner
    {
        require(
            _adminBalance >= amount,
            "Withdraw amount should be less than balance of player"
        );

        // Send BNB From Contract to Admin Address
        (bool adminWithdraw, ) = adminAddress.call{value: amount}("");
        require(adminWithdraw, "Failed to Withdraw BNB to Admin.");

        // Update Admin Balance
        _adminBalance = _adminBalance.sub(amount);

        // Emit Withdraw BNB to User
        emit WithdrawBNBToAdmin(adminAddress, amount);
    }

    /**
     * @dev Emergency Withdraw Token
     */
    function emergencyWithdrawToken(address token) external onlyOwner {
        uint256 tokenAmount = IBEP20(token).balanceOf(address(this));
        require(tokenAmount > 0, "Non token exists");

        IBEP20(token).transfer(_msgSender(), tokenAmount);
    }

    /**
     * @dev Emergency Withdraw BNB
     */
    function emergencyWithdrawBNB() external onlyOwner {
        uint256 bnbAmount = address(this).balance;
        require(bnbAmount > 0, "Non BNB exists");

        (bool emergencyWithdraw, ) = msg.sender.call{value: bnbAmount}("");
        require(
            emergencyWithdraw,
            "Failed to emergency Withdraw BNB to Admin."
        );
    }

    /**
     * @dev Play Dice Game
     */
    function playDiceGame(
        uint256 gameId,
        address[] memory playerList,
        uint256[] memory playerScoreList,
        uint256 playAmount
    ) external onlyOwner {
        uint256 i;
        require(
            playerList.length == playerScoreList.length,
            "The length should be same."
        );

        uint256 length = playerList.length;

        // Check Game Player Balance
        for (i = 0; i < length; i += 1) {
            require(
                _balanceOf[playerList[i]] >= playAmount,
                "The balance of all players should be more than playAmount."
            );
        }

        // Get Winner
        uint256 winnerId = 0;
        for (i = 1; i < length; i += 1) {
            if (playerScoreList[winnerId] < playerScoreList[i]) {
                winnerId = i;
            }
        }

        uint256 totalAmount = playAmount.mul(length);
        uint256 feeAmount = totalAmount.mul(_feePercent).div(10000);
        uint256 winnerAmount = totalAmount.sub(feeAmount);

        // Update Player's Balance
        for (i = 0; i < length; i += 1) {
            _balanceOf[playerList[i]] = _balanceOf[playerList[i]].sub(
                playAmount
            );
        }

        // Update Winner's Balance
        _balanceOf[playerList[winnerId]] = _balanceOf[playerList[winnerId]].add(
            winnerAmount
        );

        // Update Admin Balance
        _adminBalance = _adminBalance.add(feeAmount);

        // Emit the event
        emit DiceGame(gameId, playerList[winnerId], winnerAmount, feeAmount);
    }
}
