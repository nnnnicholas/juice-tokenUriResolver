//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@juicebox/interfaces/IJBTokenUriResolver.sol";
import "@juicebox/interfaces/IJBSingleTokenPaymentTerminalStore.sol";
import "juice-project-handles/interfaces/IJBProjectHandles.sol";
import "base64/base64.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "./ITypeface.sol";

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
        IJBFundingCycleStore fundingCycleStore = IJBFundingCycleStore(
            0x6f18cF9173136c0B5A6eBF45f19D58d3ff2E17e6
        );

        IJBProjects projects = IJBProjects(
            0xD8B4359143eda5B2d763E127Ed27c77addBc47d3
        );

        IJBDirectory directory = IJBDirectory(
            0xCc8f7a89d89c2AB3559f484E0C656423E979ac9C
        );

        IJBTokenStore tokenStore = IJBTokenStore(
            0x6FA996581D7edaABE62C15eaE19fEeD4F1DdDfE7
        );

        IJBProjectHandles projectHandles = IJBProjectHandles(
            0xE3c01E9Fd2a1dCC6edF0b1058B5757138EF9FfB6
        );
        IJBSingleTokenPaymentTerminalStore singleTokenPaymentTerminalStore = IJBSingleTokenPaymentTerminalStore(
                0xdF7Ca703225c5da79A86E08E03A206c267B7470C
            );

        ITypeface capsulesTypeface = ITypeface(
            0xA77b7D93E79f1E6B4f77FaB29d9ef85733A3D44A
        );

        IJBPaymentTerminal primaryEthPaymentTerminal = directory
            .primaryTerminalOf(_projectId, address(0));

        bytes memory fontSource = ITypeface(capsulesTypeface).sourceOf(
            Font({weight: 400, style: "normal"})
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

        // Get current funding cycle
        FundingCycle memory fundingCycle = fundingCycleStore.currentOf(
            _projectId
        );
        uint256 currentFundingCycleId = fundingCycle.id;

        // Get balance
        uint256 balance = singleTokenPaymentTerminalStore.balanceOf(
            _projectId,
            currentFundingCycleId
        );

        // Get distribution limit
        uint256 distributionLimit = singleTokenPaymentTerminalStore
            .distributionLimitOf(
                primaryEthPaymentTerminal,
                _projectId,
                currentFundingCycleId
            );

        // Get total supply of project token
        uint256 totalSupply = tokenStore.totalSupplyOf(_projectId);

        // Get project owner
        address owner = projects.ownerOf(_projectId);

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
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="400" version="1.1"><style>.capsules-400{ white-space: pre; font-family: Capsules-400 } @font-face { font-family: "Capsules-400"; src: url(data:font/truetype;charset=utf-8;base64,',
                fontSource,
                ') format("opentype")}</style> <rect width="300" height="400" stroke="black" stroke-width="6" fill="#ffaf03"/> <text class="capsules-400" xml:space="preserve" style="font-size:42px;line-height:1;word-spacing:0px;white-space:pre" transform="translate(0,0)"> <tspan x="19" y="52">',
                projectName,
                '</tspan> </text> <text class="capsules-400" xml:space="preserve" style="font-size:42.6667px;line-height:1;word-spacing:0px;white-space:pre" transform="translate(0,192)"> <tspan x="19" y="52" style="fill:#ff0000">',
                'Overflow </tspan> <tspan x="19" y="96" style="fill:#ff0000">',
                (overflow / 10**18).toString(),
                "ETH </tspan> </text></svg>"
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
