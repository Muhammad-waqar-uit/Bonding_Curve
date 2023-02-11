// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
error LowOnEther(uint amount,uint balance);
error LowonBalance(uint amount,uint tokens);
error CapExceeded(uint amount,uint mintcap);
contract BondingCurveToken is ERC20, Ownable {
    uint256 private _loss;

    uint256 private immutable _slope;

    // The percentage of loss when selling tokens (using two decimals)
    uint256 private  _LOSS_FEE_PERCENTAGE = 1000;
    //user cannot mint more than 100 tokens at once
    uint256 private mintcap=100;
    //total supply that can be setbyowner;
    uint256 private supplycap=100000;

    event Buy(address indexed buyer,uint amount,uint totalSupply,uint price);
    event selltoken(address indexed seller,uint amount,uint totalSupply,uint price);
    event withdrawn(address indexed from,address indexed to,uint amount);
    /**
     * @dev Constructor to initialize the contract.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     * @param slope_ The slope of the bonding curve.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint slope_,
        uint _supplycap
    ) ERC20(name_, symbol_) {
        _slope = slope_;
        supplycap=_supplycap;
    }

    /**
     * @dev Allows a user to buy tokens.
     * @param _amount The number of tokens to buy.
     */
    function buy(uint256 _amount) external payable {
        require(totalSupply()+_amount<=supplycap,"Cannot Exceed the supply cap");
        uint price = _calculatePriceForBuy(_amount);
        if (msg.value<price){
            revert LowOnEther(msg.value,address(msg.sender).balance);
        }
        if (_amount>mintcap){
            revert CapExceeded(_amount,mintcap);
        }
        _mint(msg.sender, _amount);
        payable(msg.sender).transfer(msg.value - price);
        emit Buy(msg.sender,_amount,totalSupply(),price);
    }

    /**
     * @dev Allows a user to sell tokens at a 10% loss.
     * @param _amount The number of tokens to sell.
     */
    function sell(uint256 _amount) external {
        if(balanceOf(msg.sender)< _amount){
            revert LowonBalance(_amount,balanceOf(msg.sender));
        }
        uint256 _price = _calculatePriceForSell(_amount);
        uint tax = _calculateLoss(_price);
        _burn(msg.sender, _amount);
        _loss += tax;
        payable(msg.sender).transfer(_price - tax);
        emit selltoken(msg.sender,_amount,totalSupply(),getCurrentPrice());
    }

    /**
     * @dev Allows the owner to withdraw the lost ETH.
     */
    function withdraw() external onlyOwner {
        if (_loss<=0){
            revert LowOnEther(_loss,_loss);
        }
        uint amount = _loss;
        _loss = 0;
        payable(owner()).transfer(amount);
        emit withdrawn(address(this), msg.sender, amount);
    }

    /**
     * @dev Returns the current price of the token based on the bonding curve formula.
     * @return The current price of the token in wei.
     */
    function getCurrentPrice() public view returns (uint) {
        return _slope * totalSupply();
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
        return
            (_slope *
                (_tokensToBuy *
                    (_tokensToBuy + 1) +
                    2 *
                    totalSupply() *
                    _tokensToBuy)) / 2;
    }

    /**
     * @dev Calculates the price for selling a certain number of tokens based on the bonding curve formula.
     * @param _tokensToSell The number of tokens to sell.
     * @return The price in wei for the specified number of tokens
     */
    function _calculatePriceForSell(
        uint256 _tokensToSell
    ) private view returns (uint256) {
        uint totalSupply = totalSupply();
        if (_tokensToSell > totalSupply) {
            _tokensToSell = totalSupply;
        }
        return
            _slope *
            ((_tokensToSell * (totalSupply + totalSupply - _tokensToSell + 1)) /
                2);
    }

    /**
     * @dev Calculates the loss for selling a certain number of tokens.
     * @param amount The price of the tokens being sold.
     * @return The loss in wei.
     */
    function _calculateLoss(uint256 amount) private view returns (uint256) {
        return (amount * _LOSS_FEE_PERCENTAGE) / (1E4);
    }

    function viewTax() public view  onlyOwner returns (uint256){
        return _loss;
    }

    function setLoss(uint loss) external onlyOwner returns (uint256){
        require(_LOSS_FEE_PERCENTAGE<5000,"Require it to be less than 5000");
        _LOSS_FEE_PERCENTAGE=loss;
        return _LOSS_FEE_PERCENTAGE;
    }

    function setmintcap(uint _mintcap) public onlyOwner returns(uint256){
        require(mintcap>=10,"Value should be greater than 10");
        mintcap=_mintcap;
        return _mintcap;
    }

    function changesupplycap(uint _totalSupply) public onlyOwner returns (uint256){
        require(supplycap
        >=0,"Supply cannot be zero");
        supplycap=_totalSupply;
        return _totalSupply;
    }

    function getsupplycap() public view returns(uint256){
        return supplycap;
    }
    function getminsupply() public view returns(uint256){
        return mintcap;
    }
}