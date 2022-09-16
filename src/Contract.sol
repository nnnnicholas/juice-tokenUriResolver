//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol-v2/contracts/interfaces/IJBTokenUriResolver.sol';
import '../lib/juice-project-handles/contracts/interfaces/IJBProjectHandles.sol';

contract TokenUriResolver is IJBTokenUriResolver { // TODO Make ownable
  function getUri(uint256 _projectId) external view override returns (string memory tokenUri) {
    string memory projectName;
    IJBProjectHandles projectHandles = IJBProjectHandles(0xe3c01e9fd2a1dcc6edf0b1058b5757138ef9ffb6); 

    // If handle is set
    if (projectHandles.handleOf(_projectId) != '') {
      // Set projectName to handle
      projectName = projectHandles.handleOf(_projectId);
    } else {
      // Set projectName to name to 'Project #projectId'
      projectName = string(abi.encodePacked('Project #', _projectId));
    }
    string memory uri = string(abi.encodePacked(projectName));
    return uri;
  }
}
