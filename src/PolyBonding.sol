// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenBondingCurve_Expo is ERC20, Ownable {
    uint256 private _loss;

    uint256 private immutable _constant;
    uint256 private immutable _exponent;
    // The percentage of loss when selling tokens (using two decimals)
    uint256 private constant _LOSS_FEE_PERCENTAGE = 1000;

     constructor(
        string memory name_,
        string memory symbol_,
        uint exponent_,
        uint constant_
    ) ERC20(name_, symbol_) {
        _exponent = exponent_;
        _constant = constant_;
    }
    function buy(uint256 _amount) external payable {
        uint price = _calculatePriceForBuy(_amount);
        require(msg.value >= price, "Not enough Ether to buy tokens");
        _mint(msg.sender, _amount);
        payable(msg.sender).transfer(msg.value - price);
    }

    /**
     * @dev Allows a user to sell tokens at a 10% loss.
     * @param _amount The number of tokens to sell.
     */
    function sell(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Not enough tokens to sell");
        uint256 _price = _calculatePriceForSell(_amount);
        uint tax = _calculateLoss(_price);
        _burn(msg.sender, _amount);
        _loss += tax;

        payable(msg.sender).transfer(_price - tax);
    }

    /**
     * @dev Allows the owner to withdraw the lost ETH.
     */
    function withdraw() external onlyOwner {
        require(_loss > 0, "No ETH to withdraw");
        uint amount = _loss;
        _loss = 0;
        payable(owner()).transfer(amount);
    }

    /**
     * @dev Returns the current price of the token based on the bonding curve formula.
     * @return The current price of the token in wei.
     */
    function getCurrentPrice() external view returns (uint) {
        return _calculatePriceForBuy(1);
    }

    /**
     * @dev Returns the price for buying a specified number of tokens.
     * @param _tokensToBuy The number of tokens to buy.
     * @return The price in wei.
     */
    function calculatePriceForBuy(
        uint256 _tokensToBuy
    ) external view returns (uint256) {
        return _calculatePriceForBuy(_tokensToBuy);
    }

    /**
     * @dev Returns the price for selling a specified number of tokens.
     * @param _tokensToSell The number of tokens to sell.
     * @return The price in wei.
     */
    function calculatePriceForSell(
        uint256 _tokensToSell
    ) external view returns (uint256) {
        return _calculatePriceForSell(_tokensToSell);
    }

    /**
     * @dev Calculates the price for buying a certain number of tokens based on the bonding curve formula.
     * @param _tokensToBuy The number of tokens to buy.
     * @return The price in wei for the specified number of tokens.
     */
    function _calculatePriceForBuy(
        uint256 _tokensToBuy
    ) private view returns (uint256) {
        //total supply
        uint ts=totalSupply();
        //total supply after
        uint tsafter=ts+_tokensToBuy;
        return areaundercurve(tsafter)-areaundercurve(ts);
    }

    /**
     * @dev Calculates the price for selling a certain number of tokens based on the bonding curve formula.
     * @param _tokensToSell The number of tokens to sell.
     * @return The price in wei for the specified number of tokens
     */
    function _calculatePriceForSell(
        uint256 _tokensToSell
    ) private view returns (uint256) {
        //total supply
        uint ts=totalSupply();
        //total supply after
        uint tsafter=ts-_tokensToSell;
        return areaundercurve(ts)-areaundercurve(tsafter);
    }

   function areaundercurve(uint x) internal view returns (uint256) {
        uint _exp_inc = _exponent + 1;
        return ((x **_exp_inc) + (_exp_inc * _constant * x)) / _exp_inc ;
    }
    /**
     * @dev Calculates the loss for selling a certain number of tokens.
     * @param amount The price of the tokens being sold.
     * @return The loss in wei.
     */
    function _calculateLoss(uint256 amount) private pure returns (uint256) {
        return (amount * _LOSS_FEE_PERCENTAGE) / (1E4);
    }

      function viewloss() external view onlyOwner returns (uint256) {
        return _loss;
    }
}