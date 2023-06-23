pragma solidity >=0.8.0;

import {console2} from "forge-std/console2.sol";
import {console} from "forge-std/console.sol";
import {Zi_Setup} from "./ZiSetup.t.sol";
import {SafeMath} from "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract Zi_Test is Zi_Setup {
    using SafeMath for uint256;
    uint256 bob_mint_amount = 10 ** 4;
    uint256 bob_burn_amount = 10 ** 3;

    function test_supplyLimit() public {
        console.log("Supply limit:", zi.supplyLimit());
    }

    function test_owner_cannot_mint_beyond_totalSupply() public {
        // Try to mint more than the total supply
        uint256 mint_amount = 10 ** 6 * 10 ** zi.decimals() + 1;

        vm.expectRevert("Hitting supply limit");
        zi.mint(bob, mint_amount);
    }

    function test_owner_cannot_burn_entire_supply() public {
        uint256 initialSupply = zi.initialSupply();
        // Try to mint more than the total supply

        vm.expectRevert("You cannot burn the entire supply");
        zi.burn(address(this), initialSupply);
    }

    function test_cannot_burn_tokens_of_others() public {
        // Alice tries to burn Bob's tokens

        vm.expectRevert("Burning other people's tokens!");
        zi.burn(bob, 10);
    }

    function test_can_add_minter() public {
        assertFalse(zi.isMinter(bob));
        // We adds Bob as a minter

        bool success = zi.configureMinter(bob, zi.remainingSupply().div(10000));
        assertTrue(success);
        assertTrue(zi.isMinter(bob));
        // // Bob can mint now
        vm.prank(bob);
        zi.mintByMinter(bob, uint256(bob_mint_amount));
        assertEq(zi.totalSupply(), zi.initialSupply() + bob_mint_amount);
        assertEq(zi.balanceOf(bob), bob_mint_amount);
        // Bob can burn now
        vm.prank(bob);
        zi.burnByMinter(bob, bob_mint_amount);
        assertEq(zi.totalSupply(), zi.initialSupply());
        assertEq(zi.balanceOf(bob), 0);
    }

    function test_can_remove_minter() public {
        assertFalse(zi.isMinter(bob));
        // We add Bob as a minter then removes him
        zi.configureMinter(bob, zi.remainingSupply().div(10000));

        bool success = zi.removeMinter(bob);
        assertTrue(success);
        assertTrue(!zi.isMinter(bob));
    }

    function test_removing_minter_takes_away_minting_and_burning_rights()
        public
    {
        // We add Bob as a minter then removes him

        zi.configureMinter(bob, zi.remainingSupply().div(10000));
        // Bob can mint now
        vm.prank(bob);
        zi.mintByMinter(bob, bob_mint_amount);
        assertEq(zi.totalSupply(), zi.initialSupply() + bob_mint_amount);
        assertEq(zi.balanceOf(bob), bob_mint_amount);
        // Bob can burn now
        vm.prank(bob);
        zi.burnByMinter(bob, bob_burn_amount);
        assertEq(
            zi.totalSupply(),
            zi.initialSupply() + bob_mint_amount - bob_burn_amount
        );
        assertEq(zi.balanceOf(bob), bob_mint_amount - bob_burn_amount);
        // Removing Bob as a minter

        bool success = zi.removeMinter(bob);
        assertTrue(success);
        assertTrue(!zi.isMinter(bob));
        // Bob burns again and it will fail
        vm.prank(bob);
        vm.expectRevert("Not on the allow list");
        zi.burnByMinter(bob, bob_burn_amount);
        assertEq(
            zi.totalSupply(),
            zi.initialSupply() + bob_mint_amount - bob_burn_amount
        );
        assertEq(zi.balanceOf(bob), bob_mint_amount - bob_burn_amount);
    }

    function test_can_disable_and_enable_minter() public {
        // We add Bob as a minter then disables him

        zi.configureMinter(bob, zi.remainingSupply().div(10000));
        // You can do this a hundred times
        uint256 supply = zi.initialSupply();
        for (uint256 i = 0; i <= 100; i++) {
            // We disable bob as a minter.

            zi.disableMinter(bob);
            // Bob is no longer an allowed minter;
            assertFalse(zi.enabledMinters(bob));
            // But Bob is still a minter
            assertTrue(zi.isMinter(bob));
            // Bob tries to mint and burn - but it will fail
            vm.prank(bob);
            vm.expectRevert("Minter not enabled");
            zi.mintByMinter(bob, bob_burn_amount);
            vm.expectRevert("Minter not enabled");
            zi.burnByMinter(bob, bob_burn_amount);

            // We enable Bob again

            zi.enableMinter(bob);
            assertTrue(zi.enabledMinters(bob));

            // Bob tries to mint and burn - and it will succeed
            vm.prank(bob);
            zi.mintByMinter(bob, bob_mint_amount);
            assertEq(zi.totalSupply(), supply + bob_mint_amount);
            vm.prank(bob);
            zi.burnByMinter(bob, bob_burn_amount);
            assertEq(
                zi.totalSupply(),
                supply + bob_mint_amount - bob_burn_amount
            );
            supply = zi.totalSupply();
        }
    }

    function test_can_disable_and_enable_all_minters() public {
        // We add Bob, Carol, and Dominic as minters

        address[3] memory minters = [bob, carol, dominic];
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];

            zi.configureMinter(minter, zi.remainingSupply().div(10000));
            assertTrue(zi.isMinter(minter));
        }

        // We disable all minters
        zi.disableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(!zi.enabledMinters(minter));
        }

        // Case 1: We enable all and disables 1 - she can still enable all

        // We enable all minters again

        zi.enableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(zi.enabledMinters(minter));
        }

        // We disable Bob and then enable all, we can then still proceed to enable all

        zi.disableMinter(bob);
        assertTrue(zi.isMinter(bob) && !zi.enabledMinters(bob));
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            if (minter != bob) {
                assertTrue(zi.isMinter(minter));
                assertTrue(zi.enabledMinters(minter));
            }
        }
        // We proceed to eanble all minters

        zi.enableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(zi.enabledMinters(minter));
        }
        // Case 2: We enable all and disable 1 - she can then still proceed to disable all

        zi.disableMinter(bob);
        assertTrue(zi.isMinter(bob) && !zi.enabledMinters(bob));
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            if (minter != bob) {
                assertTrue(zi.isMinter(minter));
                assertTrue(zi.enabledMinters(minter));
            }
        }

        zi.disableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(!zi.enabledMinters(minter));
        }

        // Case 3: We disable all and enable 1 - we can still proceed to enable all

        zi.enableMinter(bob);
        assertTrue(zi.isMinter(bob) && zi.enabledMinters(bob));
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            if (minter != bob) {
                assertTrue(zi.isMinter(minter));
                assertTrue(!zi.enabledMinters(minter));
            }
        }

        zi.enableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(zi.enabledMinters(minter));
        }

        // Case 4: We disable all and enables 1 - we can then proceed to enable all
        zi.disableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(!zi.enabledMinters(minter));
        }

        zi.enableMinter(bob);
        assertTrue(zi.isMinter(bob) && zi.enabledMinters(bob));
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            if (minter != bob) {
                assertTrue(zi.isMinter(minter));
                assertTrue(!zi.enabledMinters(minter));
            }
        }

        zi.enableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(zi.enabledMinters(minter));
        }
    }

    function test_disabling_all_minters_leaves_the_owner_alone() public {
        // We add Bob, Carol, and Dominic as minters
        address[3] memory minters = [bob, carol, dominic];
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];

            zi.configureMinter(minter, zi.remainingSupply().div(10000));
            assertTrue(zi.isMinter(minter));
        }

        zi.disableAllMinters();
        zi.mint(address(this), 10 ** 5);
    }

    // function test_owner_cannot_be_added_or_removed_from_minter_list() public {
    //     vm.expectRevert();
    //     zi.configureMinter(address(this), zi.remainingSupply().div(10000));

    //     // vm.expectRevert("You cannot remove the owner!");
    //     // zi.removeMinter(address(this));
    // }

    function test_cannot_remove_minter_twice() public {
        zi.configureMinter(bob, zi.remainingSupply().div(10000));
        zi.removeMinter(bob);
        vm.expectRevert("Address not on list of minter addresses!");
        zi.removeMinter(bob);
    }
}
