// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/TokenUriResolver.sol";
// import "juice-project-handles/interfaces/IJBProjectHandles.sol";
// import "base64/base64.sol";


contract ContractTest is Test {
    TokenUriResolver c = new TokenUriResolver();

    // IJBProjects jbProjects = IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3); // mainnet

    function testGetUri() external {
        string memory x = c.getUri(305);
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./open.js";
        inputs[2] = x;
        bytes memory res = vm.ffi(inputs);
    }

}
