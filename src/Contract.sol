//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@juicebox/interfaces/IJBTokenUriResolver.sol";
import "@juicebox/interfaces/IJBSingleTokenPaymentTerminalStore.sol";
import "juice-project-handles/interfaces/IJBProjectHandles.sol";
import "base64/base64.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract TokenUriResolver is
    IJBTokenUriResolver // TODO Make ownable
{
    using Strings for uint256;

    function getUri(uint256 _projectId)
        external
        view
        override
        returns (string memory tokenUri)
    {
        string memory projectName;
        IJBDirectory directory = IJBDirectory(
            0xCc8f7a89d89c2AB3559f484E0C656423E979ac9C
        );
        IJBProjectHandles projectHandles = IJBProjectHandles(
            0xE3c01E9Fd2a1dCC6edF0b1058B5757138EF9FfB6
        );
        IJBSingleTokenPaymentTerminalStore singleTokenPaymentTerminalStore = IJBSingleTokenPaymentTerminalStore(
                0x96a594ABE6B910E05E486b63B32fFe29DA5d33f7
            );

        // If handle is set
        if (
            keccak256(abi.encode(projectHandles.handleOf(_projectId))) !=
            keccak256(abi.encode(string("")))
        ) {
            // Set projectName to handle
            projectName = projectHandles.handleOf(_projectId);
        } else {
            // Set projectName to name to 'Project #projectId'
            projectName = string(abi.encodePacked("Project #", _projectId.toString()));
        }

        // Get overflow
        uint256 overflow = singleTokenPaymentTerminalStore
            .currentTotalOverflowOf(_projectId, 18, 1);

        string[] memory parts = new string[](3);
        // TODO wrap in metadata JSON 
        parts[0] = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="400" version="1.1">',
                '<rect width="300" height="400" stroke="black" stroke-width="6" fill="#ffaf03"/>',
                '<text xml:space="preserve" style="font-size:42px;line-height:1;font-family:sans-serif;word-spacing:0px;white-space:pre;shape-inside:url(#rect3919)"><tspan x="19" y="50"><tspan style="font-family:Helvetica;-inkscape-font-specification:Helvetica">',
                projectName,
                "</tspan></tspan></text>",
                '<text xml:space="preserve" style="font-size:42.6667px;line-height:1;font-family:sans-serif;word-spacing:0px;white-space:pre;shape-inside:url(#rect9222)" transform="translate(0,192.98246)"><tspan x="17.542969"y="52.328557"><tspan style="font-family:Helvetica;-inkscape-font-specification:Helvetica;fill:#ff0000">Overflow </tspan></tspan><tspan x="17"y="96"><tspan style="font-family:Helvetica;-inkscape-font-specification:Helvetica;fill:#ff0000">',
                (overflow/10**18).toString(),
                'ETH',
                "</tspan></tspan></text>",
                "</svg>"
            )
        );
        string memory uri = Base64.encode(abi.encodePacked(parts[0]));
        return uri;
    }
}
