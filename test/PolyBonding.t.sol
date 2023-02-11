// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/PolyBonding.sol";
import "lib/forge-std/src/Test.sol";

contract TokenBondingCurve_PolyTest is Test {
    TokenBondingCurve_polynomial  public TBPC;     
    address user = address(1);
    address deployer = address(2);

    function setUp() public {
        vm.prank(deployer);
        TBPC = new TokenBondingCurve_polynomial("PTKN", "Poly", 2,1);
    }

    function testBuy() public {
        uint amount = 5;
        uint oldBal = address(TBPC).balance;
        uint val = TBPC.calculatePriceForBuy(amount);
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        TBPC.buy{value: val}(amount);
        assertEq(TBPC.totalSupply(), amount);
        assertEq(address(TBPC).balance, oldBal + val);
        vm.stopPrank();
    }

    function testNotBuyingToken() public {
        vm.expectRevert(
            abi.encodeWithSelector(LowOnEther.selector, 0, 0)
        );
        // vm.expectRevert("LowOnEther(0, 0)");
        vm.startPrank(user);
        TBPC.buy(5);
        vm.stopPrank();
    }

     function testBuyrandom(uint amount) public {
        vm.assume(amount > 0 && amount < 3000000000);
        uint oldBal = address(TBPC).balance;
        uint val = TBPC.calculatePriceForBuy(amount);
        vm.deal(user, 1000000000000000000000 ether);
        vm.startPrank(user);
        TBPC.buy{value: val}(amount);
        assertEq(TBPC.totalSupply(), amount);
        assertEq(address(TBPC).balance, oldBal + val);
        vm.stopPrank();
    }
     function testNot_Selling_Token() public {
        vm.expectRevert(
            abi.encodeWithSelector(LowTokenBalance.selector, 6, 0)
        );
        vm.startPrank(user);
        TBPC.sell(6);
        vm.stopPrank();
    }

    function testNot_Withdraw_amount() public {
        vm.expectRevert(
            abi.encodeWithSelector(LowOnEther.selector, 0, 0)
        );
        vm.startPrank(deployer);
        TBPC.withdraw();
        vm.stopPrank();
    }

    function systemcheck_random(uint amount)public{
        vm.assume(amount>0 && amount <=8000000);
        uint oldbal=address(TBPC).balance;
    uint val=TBPC.calculatePriceForBuy(amount);
    vm.deal(user,10000000000000000000000000000000000 ether);

    vm.prank(user);
    TBPC.buy{value:val}(amount);
    assertEq(TBPC.totalSupply(), amount);
    assertEq(address(TBPC).balance,oldbal+val);
    }
}