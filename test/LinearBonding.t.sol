// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/LinearBonding.sol";
import "lib/forge-std/src/Test.sol";

contract TokenBondingCurve_LinearTest is Test {
    BondingCurveToken public TBLC;     
    address user = address(1);
    address deployer = address(2);

    function setUp() public {
        vm.prank(deployer);
        TBLC = new BondingCurveToken("MTKN", "M", 1,3400000000000);
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

    function testNotBuyingToken() public {
        vm.expectRevert(
            abi.encodeWithSelector(LowOnEther.selector, 0, 0)
        );
        // vm.expectRevert("LowOnEther(0, 0)");
        vm.startPrank(user);
        TBLC.buy(5);
        vm.stopPrank();
    }

     function testBuyrandom(uint amount) public {
        vm.assume(amount > 0 && amount < 3000000000);
        uint oldBal = address(TBLC).balance;
        uint val = TBLC.calculatePriceForBuy(amount);
        vm.deal(user, 1000000000000000000000 ether);
        vm.startPrank(user);
        TBLC.buy{value: val}(amount);
        assertEq(TBLC.totalSupply(), amount);
        assertEq(address(TBLC).balance, oldBal + val);
        vm.stopPrank();
    }
     function testNot_Selling_Token() public {
        vm.expectRevert(
            abi.encodeWithSelector(LowonBalance.selector, 6, 0)
        );
        vm.startPrank(user);
        TBLC.sell(6);
        vm.stopPrank();
    }

    function testNot_Withdraw_amount() public {
        vm.expectRevert(
            abi.encodeWithSelector(LowOnEther.selector, 0, 0)
        );
        vm.startPrank(deployer);
        TBLC.withdraw();
        vm.stopPrank();
    }

    function systemcheck_random(uint amount)public{
        vm.assume(amount>0 && amount <=8000000);
        uint oldbal=address(TBLC).balance;
    uint val=TBLC.calculatePriceForBuy(amount);
    vm.deal(user,10000000000000000000000000000000000 ether);

    vm.prank(user);
    TBLC.buy{value:val}(amount);
    assertEq(TBLC.totalSupply(), amount);
    assertEq(address(TBLC).balance,oldbal+val);
    }
}