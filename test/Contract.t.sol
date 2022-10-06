// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Contract.sol";
import "juice-project-handles/interfaces/IJBProjectHandles.sol";

contract ContractTest is Test {

  TokenUriResolver c = new TokenUriResolver();
  // IJBProjects jbProjects = IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3); // mainnet

  function testHandleOf() external {
    c.getUri(1);
  }

}