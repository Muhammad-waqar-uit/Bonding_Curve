// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


import "src/LinearBonding.sol";
import "lib/forge-std/src/Test.sol";


contract TokenBondingCurve_LinearTest is Test {
    BondingCurveToken public TBLC;     
    address user = address(1);
    address deployer = address(100);
    event tester(uint);

    function setUp() public {
        vm.prank(deployer);
        TBLC = new BondingCurveToken("QTKN", "Q", 2);
    }

    function testBuy() public {
        uint amount = 5;
        uint oldBal = address(TBLC).balance;
        uint val = TBLC.calculatePriceForBuy(amount);
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        TBLC.buy{value: val}(amount);
        assertEq(TBLC.totalSupply(), amount);
        assertEq(address(TBLC).balance, oldBal + val);
        vm.stopPrank();
    }

    function testCannot_Buy() public {
        vm.expectRevert(
            abi.encodeWithSelector(LowBalance.selector, 0, 0)
        );
        // vm.expectRevert("LowOnEther(0, 0)");
        vm.startPrank(user);
        TBLC.buy(5);
        vm.stopPrank();
    }

    function testBuy_withFuzzing(uint amount) public {
        // vm.assume(amount > 40000050 && amount < 50000000);
        vm.assume(amount > 0 && amount < 900000000000);
        uint oldBal = address(TBLC).balance;
        uint val = TBLC.calculatePriceForBuy(amount);
        vm.deal(user, 1000000000000000000000000000000000000 ether);
        vm.startPrank(user);
        TBLC.buy{value: val}(amount);
        assertEq(TBLC.totalSupply(), amount);
        assertEq(address(TBLC).balance, oldBal + val);
        vm.stopPrank();
    }

    function testSystem_withFuzzing(uint amount) public {
        // vm.assume(amount > 40000050 && amount < 50000000);
        //assumptions
        
        vm.assume(amount > 0 && amount <= 900000000000);

        //save some variables
        uint oldBal = address(TBLC).balance;
        uint val = TBLC.calculatePriceForBuy(amount);

        //deal user some ether
        vm.deal(user, 1000000000000000000000000000000000000 ether); 

        //start
        vm.prank(user);
        //buy tkns
        TBLC.buy{value: val}(amount);
        //check if total supply increases
        assertEq(TBLC.totalSupply(), amount);

        //check if balance increases
        assertEq(address(TBLC).balance, oldBal + val);

        //check if tax is zero
        vm.prank(TBLC.owner());
        assertEq(TBLC.viewTax(), 0);

        oldBal = address(TBLC).balance;

        //buy 10 more tokens
        uint price1 = TBLC.calculatePriceForBuy(10);
        vm.prank(user);
        TBLC.buy{value: price1}(10);

        //check if total supply increases
        assertEq(TBLC.totalSupply(), amount + 10);

        //check if balance increases
        assertEq(address(TBLC).balance, oldBal + price1);

        //check if tax is zero
        vm.prank(TBLC.owner());
        assertEq(TBLC.viewTax(), 0);

        oldBal = address(TBLC).balance;

        uint cs = TBLC.totalSupply();

        uint price2 = TBLC.calculatePriceForSell(5);
        vm.prank(user);
        TBLC.sell(5);

        //find out tax
        vm.prank(TBLC.owner());
        uint tax = TBLC.viewTax();

        //TODO: fix assertions from here
        //check if total supply increases
        assertEq(TBLC.totalSupply(), cs - 5);

        //check if balance decreases
        assertEq(address(TBLC).balance, oldBal - price2 + tax);

        //check if tax is not zero
        assertEq(tax, ((price2 * 1000) / 10000));
        //sell rest of tokens
        uint price3 = TBLC.calculatePriceForSell(TBLC.totalSupply());
        uint ts = TBLC.totalSupply();
        vm.prank(user);
        TBLC.sell(ts);

        //find out tax
        vm.prank(TBLC.owner());
        tax = TBLC.viewTax();

        //check if total supply decreases
        assertEq(TBLC.totalSupply(), 0);

        //check if tax is not zero
        assertEq(tax, ((price3 * 1000) / 10000) + ((price2 * 1000) / 10000));

        //check if balance decreases
        assertEq(address(TBLC).balance, tax);
        uint oldOwnerBal = TBLC.owner().balance;
        vm.prank(TBLC.owner());
        TBLC.withdraw();
        emit tester(TBLC.owner().balance);
        assertEq(TBLC.owner().balance, oldOwnerBal + tax);

    }

    function testCannot_Sell() public {
        vm.expectRevert(
            abi.encodeWithSelector(LowTokenBalance.selector, 6, 0)
        );
        vm.startPrank(user);
       TBLC.sell(6);
        vm.stopPrank();
    }

}