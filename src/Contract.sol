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
            projectName = string(
                abi.encodePacked("Juicebox Project # ", _projectId.toString())
            );
        }

        // Get overflow
        uint256 overflow = singleTokenPaymentTerminalStore
            .currentTotalOverflowOf(_projectId, 18, 1);

        string[] memory parts = new string[](4);
        parts[0] = string("data:application/json;base64,");
        parts[1] = string(
            abi.encodePacked(
                '{"name":"',
                projectName,
                '", "description":"',
                projectName,
                " is a project on the Juicebox Protocol. It has an overflow of ",
                (overflow / 10**18).toString(),
                ' ETH.", "image":"data:image/svg+xml;base64,'
            )
        );
        
        parts[2] = Base64.encode(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="400" version="1.1"> <rect width="300" height="400" stroke="black" stroke-width="6" fill="#ffaf03"/> <text xml:space="preserve" style="font-size:42px;line-height:1;font-family:sans-serif;word-spacing:0px;white-space:pre" transform="translate(0,0)"> <tspan x="19" y="52" style="font-family:Helvetica">',
                projectName,
                '</tspan> </text> <text xml:space="preserve" style="font-size:42.6667px;line-height:1;font-family:sans-serif;word-spacing:0px;white-space:pre" transform="translate(0,192)"> <tspan x="19" y="52" style="font-family:Helvetica;fill:#ff0000">',
                'Overflow </tspan> <tspan x="19" y="96" style="font-family:Helvetica;-inkscape-font-specification:Helvetica;fill:#ff0000">',
                (overflow / 10**18).toString(),
                'ETH </tspan> </text></svg>'
            )
        );
        parts[3] = string('"}');
        string memory uri = string(
            abi.encodePacked(
                parts[0],
                Base64.encode(abi.encodePacked(parts[1], parts[2], parts[3]))
            )
        );
        return uri;
    }
}
