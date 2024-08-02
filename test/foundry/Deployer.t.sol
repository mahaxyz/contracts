// SPDX-License-Identifier: GPL-3.0

// ███╗   ███╗ █████╗ ██╗  ██╗ █████╗
// ████╗ ████║██╔══██╗██║  ██║██╔══██╗
// ██╔████╔██║███████║███████║███████║
// ██║╚██╔╝██║██╔══██║██╔══██║██╔══██║
// ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

// Website: https://maha.xyz
// Discord: https://discord.gg/mahadao
// Twitter: https://twitter.com/mahaxyz_

pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../contracts/Deployer.sol"; // Adjust the path to your contract

contract DeployerTest is Test {
    Deployer deployer;

    // Import the Deploy event
    event Deploy(address addr);

    function setUp() public {
        deployer = new Deployer();
    }

    function testDeploy() public {
        // Example bytecode for a minimal contract (return 42)
        bytes memory bytecode = hex"6080604052348015600f57600080fd5b50602a80601d6000396000f3fe602a60005260206000f3";
        uint256 salt = 0x123456789;

        // Calculate the expected address
        address expectedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(deployer),
            salt,
            keccak256(bytecode)
        )))));

        // Expect the Deploy event to be emitted with the calculated address
        vm.expectEmit(true, true, true, true);
        emit Deploy(expectedAddress);

        deployer.deploy(bytecode, salt);

        // Verify that the deployed contract exists
        assertTrue(address(expectedAddress).code.length > 0, "Contract not deployed");
    }

    // function testFailDeploy() public {
    //     // Example of invalid bytecode (empty bytecode)
    //     bytes memory invalidBytecode = hex"";
    //     uint256 salt = 0x12345678;

    //     // Expect revert due to invalid bytecode
    //     vm.expectRevert();
    //     deployer.deploy(invalidBytecode, salt);
    // }
}
