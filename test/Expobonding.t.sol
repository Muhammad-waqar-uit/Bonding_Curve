// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/ExpoBonding.sol";
import "lib/forge-std/src/Test.sol";

contract TokenBondingCurve_ExponentialTest is Test {
    TokenBondingCurve_Expo public TBEC;     
    address user = address(1);
    address deployer = address(2);

    function setUp() public {
        vm.prank(deployer);
        TBEC = new TokenBondingCurve_Expo("ETKN", "EXpo", 2);
    }

    function testBuy() public {
        uint amount = 5;
        uint oldBal = address(TBEC).balance;
        uint val = TBEC.calculatePriceForBuy(amount);
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        TBEC.buy{value: val}(amount);
        assertEq(TBEC.totalSupply(), amount);
        assertEq(address(TBEC).balance, oldBal + val);
        vm.stopPrank();
    }

    function testNotBuyingToken() public {
        vm.expectRevert(
            abi.encodeWithSelector(LowOnEther.selector, 0, 0)
        );
        // vm.expectRevert("LowOnEther(0, 0)");
        vm.startPrank(user);
        TBEC.buy(5);
        vm.stopPrank();
    }

     function testBuyrandom(uint amount) public {
        vm.assume(amount > 0 && amount < 3000000000);
        uint oldBal = address(TBEC).balance;
        uint val = TBEC.calculatePriceForBuy(amount);
        vm.deal(user, 1000000000000000000000 ether);
        vm.startPrank(user);
        TBEC.buy{value: val}(amount);
        assertEq(TBEC.totalSupply(), amount);
        assertEq(address(TBEC).balance, oldBal + val);
        vm.stopPrank();
    }
     function testNot_Selling_Token() public {
        vm.expectRevert(
            abi.encodeWithSelector(LowTokenBalance.selector, 6, 0)
        );
        vm.startPrank(user);
        TBEC.sell(6);
        vm.stopPrank();
    }

    function testNot_Withdraw_amount() public {
        vm.expectRevert(
            abi.encodeWithSelector(LowOnEther.selector, 0, 0)
        );
        vm.startPrank(deployer);
        TBEC.withdraw();
        vm.stopPrank();
    }

    function systemcheck_random(uint amount)public{
        vm.assume(amount>0 && amount <=8000000);
        uint oldbal=address(TBEC).balance;
    uint val=TBEC.calculatePriceForBuy(amount);
    vm.deal(user,10000000000000000000000000000000000 ether);

    vm.prank(user);
    TBEC.buy{value:val}(amount);
    assertEq(TBEC.totalSupply(), amount);
    assertEq(address(TBEC).balance,oldbal+val);
    }
}