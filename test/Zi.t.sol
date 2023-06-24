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
        // We try to burn bob's tokens

        vm.expectRevert("Burning other people's tokens!");
        zi.burn(bob, 10);
    }

    function test_can_add_minter() public {
        uint256 minterAllowance = zi.remainingSupply().div(10000); // 1 bip of the remaining supply
        assertFalse(zi.isMinter(bob));
        // We add Bob as a minter

        bool success = zi.configureMinter(bob, minterAllowance);
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
        uint256 minterAllowance = zi.remainingSupply().div(10000); // 1 bip of the remaining supply
        assertFalse(zi.isMinter(bob));
        // We add Bob as a minter then removes him
        zi.configureMinter(bob, minterAllowance);

        bool success = zi.removeMinter(bob);
        assertTrue(success);
        assertFalse(zi.isMinter(bob));
    }

    function test_removing_minter_takes_away_minting_and_burning_rights()
        public
    {
        uint256 minterAllowance = zi.remainingSupply().div(10000); // 1 bip of the remaining supply
        // We add Bob as a minter then removes him

        zi.configureMinter(bob, minterAllowance);
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
        assertFalse(zi.isMinter(bob));
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
        uint256 minterAllowance = zi.remainingSupply().div(10000); // 1 bip of the remaining supply
        // We add Bob as a minter then disables him

        zi.configureMinter(bob, minterAllowance);
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
        uint256 minterAllowance = zi.remainingSupply().div(10000); // 1 bip of the remaining supply
        address[3] memory minters = [bob, carol, dominic];
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];

            zi.configureMinter(minter, minterAllowance);
            assertTrue(zi.isMinter(minter));
        }

        // We disable all minters
        zi.disableAllMinters();
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            assertTrue(zi.isMinter(minter));
            assertFalse(zi.enabledMinters(minter));
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
            assertFalse(zi.enabledMinters(minter));
        }

        // Case 3: We disable all and enable 1 - we can still proceed to enable all

        zi.enableMinter(bob);
        assertTrue(zi.isMinter(bob) && zi.enabledMinters(bob));
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            if (minter != bob) {
                assertTrue(zi.isMinter(minter));
                assertFalse(zi.enabledMinters(minter));
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
            assertFalse(zi.enabledMinters(minter));
        }

        zi.enableMinter(bob);
        assertTrue(zi.isMinter(bob) && zi.enabledMinters(bob));
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            if (minter != bob) {
                assertTrue(zi.isMinter(minter));
                assertFalse(zi.enabledMinters(minter));
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
        uint256 minterAllowance = zi.remainingSupply().div(10000); // 1 bip of the remaining supply
        // We add Bob, Carol, and Dominic as minters
        address[3] memory minters = [bob, carol, dominic];
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            uint256 m = zi.remainingSupply().div(10000); // 1 bip of the remaining supply
            console.log(i, "minter allowance:", m);
            zi.configureMinter(minter, m);
            assertTrue(zi.isMinter(minter));
            assertLte(minterAllowance, m);
            minterAllowance = m;
        }

        zi.disableAllMinters();
        zi.mint(address(this), 10 ** 5);
    }

    function test_owner_cannot_be_added() public {
        uint256 minterAllowance = zi.remainingSupply().div(10000); // 1 bip of the remaining supply
        vm.expectRevert("You cannot add the owner!");
        zi.configureMinter(address(this), minterAllowance);

        vm.expectRevert("You cannot remove the owner!");
        zi.removeMinter(address(this));
    }

    function test_cannot_remove_minter_twice() public {
        uint256 minterAllowance = zi.remainingSupply().div(10000); // 1 bip of the remaining supply
        zi.configureMinter(bob, minterAllowance);
        zi.removeMinter(bob);
        vm.expectRevert("Address not on list of minter addresses!");
        zi.removeMinter(bob);
    }

    function test_minters_cannot_mint_beyond_supplylimit() public {}

    // Given there's no requirement that allowances have to sum up to below the supply limit
    // minters can technically fail to mint even though they're within their allowances
    // if the supply limit has been reached.
    function test_minter_cannot_mint_more_than_allowance() public {
        uint256 minterAllowance = zi.remainingSupply().div(10000); // 1 bip of the remaining supply
        // We add Bob as a minter
        zi.configureMinter(bob, minterAllowance);

        // Bob tries to mint more than his allowance
        vm.prank(bob);
        vm.expectRevert("Insufficient allowance");
        zi.mintByMinter(bob, minterAllowance + 1);
    }

    function test_remaining_supply_logic() public {}

    function test_rescueERC20() public {
        mock.mint(address(zi), uint256(1 ether));
        uint256 balance = IERC20(address(mock)).balanceOf(address(zi));
        assertTrue(balance > 0);
        bool success = zi.rescueERC20(address(mock), address(this));
        assertTrue(success);
        balance = IERC20(address(mock)).balanceOf(address(zi));
        assertEq(balance, 0);
        assertEq(IERC20(address(mock)).balanceOf(address(zi.owner())), 1 ether);
    }

    function test_minter_burning_more_tokens_than_initial_allowance_will_not_increase_minter_allowance()
        public
    {
        // owner mints alice some tokens
        uint256 initialSupply = zi.totalSupply();
        uint256 alice_amount = 2 ether;
        uint256 minter_1_allowance = 2 ether;
        uint256 minter_1_minting_amount = 1 ether;

        zi.mint(alice, alice_amount);

        assertEq(zi.balanceOf(alice), alice_amount);

        // owner gives minter_1 a minting allowance
        zi.configureMinter(minter_1, minter_1_allowance);
        assertEq(zi.initialAllowance(minter_1), minter_1_allowance);
        assertEq(zi.minterAllowance(minter_1), minter_1_allowance);

        // minter_1 then mints some of his allowance
        vm.prank(minter_1);
        zi.mintByMinter(minter_1, minter_1_minting_amount);
        // initialAllowance is unchanged
        assertEq(zi.initialAllowance(minter_1), minter_1_allowance);
        // by allowance has decreased
        assertEq(
            zi.minterAllowance(minter_1),
            minter_1_allowance - minter_1_minting_amount
        );

        // minter_1 proceeds to mint the rest of his allowance
        vm.prank(minter_1);
        zi.mintByMinter(minter_1, minter_1_allowance - minter_1_minting_amount);
        assertEq(zi.balanceOf(minter_1), minter_1_allowance);
        // and Alice sends minter_1 his tokens
        vm.prank(alice);
        zi.transfer(minter_1, zi.balanceOf(alice));
        assertEq(zi.balanceOf(minter_1), minter_1_allowance + alice_amount);
        // then minter_1_proceeds to burn everything in his address

        vm.prank(minter_1);
        zi.burnByMinter(minter_1, minter_1_allowance + alice_amount);
        assertEq(zi.initialAllowance(minter_1), minter_1_allowance);
        assertEq(zi.minterAllowance(minter_1), minter_1_allowance);

        // so minter_1 has burned both minter_1_allowance and alice_amount
        assertEq(zi.totalSupply(), initialSupply);
    }
}
