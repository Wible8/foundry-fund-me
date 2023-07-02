// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe public fundMe;

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    address USER = makeAddr("user");

    function setUp() external {
        DeployFundMe deployer = new DeployFundMe();
        fundMe = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimalDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testVersionOfPriceFeed() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundMeWithoutFund() public {
        vm.expectRevert();

        fundMe.fund();
    }

    function testFundMeUpdateDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testAddsFunderToArray() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testOwnerWithdraw() public funded {
        uint256 startingBalanceOwner = fundMe.getOwner().balance;
        uint256 startingBalanceFundMe = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingBalanceOwner = fundMe.getOwner().balance;
        uint256 endingBalanceFundMe = address(fundMe).balance;

        assertEq(endingBalanceFundMe, 0);
        assertEq(endingBalanceOwner, startingBalanceOwner + startingBalanceFundMe);
    }

    function testOwnerWithdrawWithMultipleFunders() public {
        uint160 fundersIndex = 1;
        uint256 numberOfFunders = 10;

        for (uint160 i = fundersIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingBalanceOwner = fundMe.getOwner().balance;
        uint256 startingBalanceFundMe = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assertEq(fundMe.getOwner().balance, startingBalanceOwner + startingBalanceFundMe);
    }
}
