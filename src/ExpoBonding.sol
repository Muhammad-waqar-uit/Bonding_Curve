// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
error LowTokenBalance(uint amount,uint tokenbalance);
error LowOnEther(uint amount,uint tokenbalance);
contract TokenBondingCurve_Expo is ERC20, Ownable {
    uint256 private _loss;

    uint256 private immutable _exponent;
    // The percentage of loss when selling tokens (using two decimals)
    uint256 private constant _LOSS_FEE_PERCENTAGE = 1000;

     constructor(
        string memory name_,
        string memory symbol_,
        uint exponent_
    ) ERC20(name_, symbol_) {
        _exponent = exponent_;
    }
    function buy(uint256 _amount) external payable {
        uint price = _calculatePriceForBuy(_amount);
        if(msg.value<price){
            revert LowOnEther(msg.value,address(msg.sender).balance);
        }
        _mint(msg.sender, _amount);
         (bool sent,) = payable(msg.sender).call{value: msg.value - price}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev Allows a user to sell tokens at a 10% loss.
     * @param _amount The number of tokens to sell.
     */
    function sell(uint256 _amount) external {
        if(balanceOf(msg.sender)<_amount){
            revert LowTokenBalance(_amount,balanceOf(msg.sender));
        }
        uint256 _price = _calculatePriceForSell(_amount);
        uint tax = _calculateLoss(_price);
        _burn(msg.sender, _amount);
        _loss += tax;

       (bool sent,) = payable(msg.sender).call{value: _price - tax}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev Allows the owner to withdraw the lost ETH.
     */
    function withdraw() external onlyOwner {
        if(_loss<=0){
            revert LowOnEther(_loss,_loss);
        }
        uint amount = _loss;
        _loss = 0;
        (bool sent,) = payable(owner()).call{value: amount}("");
        require(sent, "Failed to send Ether");
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

    function areaundercurve(uint x)internal view returns(uint256){
         return (x **(_exponent + 2)) / _exponent + 2 ;
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