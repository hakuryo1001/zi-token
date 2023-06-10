pragma solidity >=0.8.0;

import {console2} from "forge-std/console2.sol";
import {console} from "forge-std/console.sol";
import {Zi_Setup} from "./ZiSetup.t.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract Zi_Test is Zi_Setup {
    uint256 bob_mint_amount = 10 ** 4;
    uint256 bob_burn_amount = 10 ** 3;

    function test_supplyLimit() public {
        console.log(zi.supplyLimit());
    }

    function test_owner_cannot_mint_beyond_totalSupply() public {
        // Try to mint more than the total supply
        uint256 mint_amount = 10 ** 6 * 10 ** zi.decimals() + 1;
        vm.prank(alice);
        vm.expectRevert("Hitting supply limit");
        zi.mint(bob, mint_amount);
    }

    function test_owner_cannot_burn_entire_supply() public {
        uint256 initialSupply = zi.initialSupply();
        // Try to mint more than the total supply
        vm.prank(alice);
        vm.expectRevert("You cannot burn the entire supply");
        zi.burn(alice, initialSupply);
    }

    function test_cannot_burn_tokens_of_others() public {
        // Alice tries to burn Bob's tokens
        vm.prank(alice);
        vm.expectRevert("Burning other people's tokens!");
        zi.burn(bob, 10);
    }

    function test_can_add_minter() public {
        assertFalse(zi.isMinter(bob));
        // Alice adds Bob as a minter
        vm.prank(alice);
        bool success = zi.addMinter(bob);
        assertTrue(success);
        assertTrue(zi.isMinter(bob));
        // Bob can mint now
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
        // Alice adds Bob as a minter then removes him
        vm.prank(alice);
        zi.addMinter(bob);
        vm.prank(alice);
        bool success = zi.removeMinter(bob);
        assertTrue(success);
        assertTrue(!zi.isMinter(bob));
    }

    function test_removing_minter_takes_away_minting_and_burning_rights()
        public
    {
        // Alice adds Bob as a minter then removes him
        vm.prank(alice);
        zi.addMinter(bob);
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
        vm.prank(alice);
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
        // Alice adds Bob as a minter then disables him
        vm.prank(alice);
        zi.addMinter(bob);
        // You can do this a hundred times
        uint256 supply = zi.initialSupply();
        for (uint256 i = 0; i <= 100; i++) {
            // Alice disables bob as a minter.
            vm.prank(alice);
            zi.disableMinter(bob);
            // Bob is no longer an allowed minter;
            assertTrue(!zi.allowedMinters(bob));
            // But Bob is still a minter
            assertTrue(zi.isMinter(bob));
            // Bob tries to mint and burn - but it will fail
            vm.prank(bob);
            vm.expectRevert("Not on the allow list");
            zi.mintByMinter(bob, bob_burn_amount);
            vm.expectRevert("Not on the allow list");
            zi.burnByMinter(bob, bob_burn_amount);

            // Alice enables Bob again
            vm.prank(alice);
            zi.enableMinter(bob);
            assertTrue(zi.allowedMinters(bob));

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
        // Alice adds Bob, Carol, and Dominic as minters

        address[3] memory minters = [bob, carol, dominic];
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            vm.prank(alice);
            zi.addMinter(minter);
            assertTrue(zi.isMinter(minter));
        }

        // Alice disables all minters;
        vm.prank(alice);
        zi.disableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(!zi.allowedMinters(minter));
        }

        // Case 1: Alice enables all and disables 1 - she can still enable all

        // Alice enables all minters again
        vm.prank(alice);
        zi.enableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(zi.allowedMinters(minter));
        }

        // Alice disables Bob and then enables all, she can then still proceed to enable all
        vm.prank(alice);
        zi.disableMinter(bob);
        assertTrue(zi.isMinter(bob) && !zi.allowedMinters(bob));
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            if (minter != bob) {
                assertTrue(zi.isMinter(minter));
                assertTrue(zi.allowedMinters(minter));
            }
        }
        // Alice proceeds to eanble all minters
        vm.prank(alice);
        zi.enableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(zi.allowedMinters(minter));
        }
        // Case 2: Alice enables all and disables 1 - she can then still proceed to disable all
        vm.prank(alice);
        zi.disableMinter(bob);
        assertTrue(zi.isMinter(bob) && !zi.allowedMinters(bob));
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            if (minter != bob) {
                assertTrue(zi.isMinter(minter));
                assertTrue(zi.allowedMinters(minter));
            }
        }
        vm.prank(alice);
        zi.disableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(!zi.allowedMinters(minter));
        }

        // Case 3: Alice disables all and enables 1 - she can still proceed to enable all
        vm.prank(alice);
        zi.enableMinter(bob);
        assertTrue(zi.isMinter(bob) && zi.allowedMinters(bob));
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            if (minter != bob) {
                assertTrue(zi.isMinter(minter));
                assertTrue(!zi.allowedMinters(minter));
            }
        }
        vm.prank(alice);
        zi.enableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(zi.allowedMinters(minter));
        }

        // Case 4: Alice disables all and enables 1 - she can then proceed to enable all
        vm.prank(alice);
        zi.disableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(!zi.allowedMinters(minter));
        }
        vm.prank(alice);
        zi.enableMinter(bob);
        assertTrue(zi.isMinter(bob) && zi.allowedMinters(bob));
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            if (minter != bob) {
                assertTrue(zi.isMinter(minter));
                assertTrue(!zi.allowedMinters(minter));
            }
        }
        vm.prank(alice);
        zi.enableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertTrue(zi.allowedMinters(minter));
        }
    }

    function test_disabling_all_minters_leaves_the_owner_alone() public {
        // Alice adds Bob, Carol, and Dominic as minters
        address[3] memory minters = [bob, carol, dominic];
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            vm.prank(alice);
            zi.addMinter(minter);
            assertTrue(zi.isMinter(minter));
        }

        vm.prank(alice);
        zi.disableAllMinters();
        vm.prank(alice);
        zi.mint(alice, 10 ** 5);
    }

    function test_cannot_add_duplicate_minter() public {
        vm.prank(alice);
        zi.addMinter(bob);
        vm.prank(alice);
        vm.expectRevert("Minter already added");
        zi.addMinter(bob);
    }

    function test_owner_cannot_be_added_or_removed_from_minter_list() public {
        vm.prank(alice);
        vm.expectRevert("You cannot add the owner!");
        zi.addMinter(alice);
        vm.prank(alice);
        vm.expectRevert("You cannot remove the owner!");
        zi.removeMinter(alice);
    }

    function test_cannot_remove_minter_twice() public {
        vm.prank(alice);
        zi.addMinter(bob);
        vm.prank(alice);
        zi.removeMinter(bob);
        vm.prank(alice);
        vm.expectRevert("Address not on list of minter addresses!");
        zi.removeMinter(bob);
    }
}
