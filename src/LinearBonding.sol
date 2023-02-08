// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenBondingCurve_Linear is ERC20, Ownable {
    uint256 private _tax;
    uint256 private immutable _slope;

    uint256 private constant LOSS_FEE_PERCENTAGE = 1000;

    constructor(string memory name_, string memory symbol_, uint slope_)
        ERC20(name_, symbol_)
    {
        _slope = slope_;
    }

    function buy(uint256 _amount) external payable {
        uint256 price = _calculatePriceForBuy(_amount);
        require(msg.value >= price, "Low on Ether");
        _mint(msg.sender, _amount);
        (bool sent,) = payable(msg.sender).call{value: msg.value - price}("");
        require(sent, "Failed to send Ether");
    }

    function sell(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Low on Tokens");
        uint256 price = _calculatePriceForSell(_amount);
        uint256 tax = _calculateLoss(price);
        _burn(msg.sender, _amount);
        _tax += tax;
        payable(msg.sender).transfer(price - tax);
    }

    function withdraw() external onlyOwner {
        require(_tax > 0, "Low on Ether");
        uint256 amount = _tax;
        _tax = 0;
        payable(owner()).transfer(amount);
    }

    function getCurrentPrice() external view returns (uint256) {
        return _slope * totalSupply();
    }

    function calculatePriceForBuy(uint256 _tokensToBuy) external view returns (uint256) {
        return _calculatePriceForBuy(_tokensToBuy);
    }

    function calculatePriceForSell(uint256 _tokensToSell) external view returns (uint256) {
        return _calculatePriceForSell(_tokensToSell);
    }

    function _calculatePriceForBuy(uint256 _tokensToBuy) private view returns (uint256) {
        uint256 price = 0;
        uint256 totalSupply = totalSupply();
        for (uint i = totalSupply + 1; i < totalSupply + _tokensToBuy + 1; i++) {
            price += i * _slope;
        }
        return price;
    }

    function _calculatePriceForSell(uint256 _tokensToSell) private view returns (uint256) {
        uint256 price = 0;
        uint256 totalSupply = totalSupply();
        for (uint i = totalSupply - _tokensToSell + 1; i <= totalSupply; i++) {
            price += i * _slope;
        }
        return price;
    }

    function _calculateLoss(uint256 price) private pure returns (uint256) {
        return price / 10;
    }
}
