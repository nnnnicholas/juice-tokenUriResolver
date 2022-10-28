//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@juicebox/interfaces/IJBTokenUriResolver.sol";
import {IJBToken, IJBTokenStore} from "@juicebox/interfaces/IJBTokenStore.sol";
import {JBFundingCycle} from "@juicebox/structs/JBFundingCycle.sol";
import {JBTokens} from "@juicebox/libraries/JBTokens.sol";
import {JBCurrencies} from "@juicebox/libraries/JBCurrencies.sol";
import {IJBController} from "@juicebox/interfaces/IJBController.sol";
import "@juicebox/interfaces/IJBSingleTokenPaymentTerminalStore.sol";
import {IJBProjectHandles} from "juice-project-handles/interfaces/IJBProjectHandles.sol";
import "base64/base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import "./ITypeface.sol";

// ENS RESOLUTION
interface IReverseRegistrar {
    function node(address) external view returns (bytes32);
}
interface IResolver{
    function name(bytes32) external view returns(string memory);
}

contract TokenUriResolver is IJBTokenUriResolver
{
    using Strings for uint256;

    IReverseRegistrar reverseRegistrar = IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148); // mainnet
    IResolver resolver = IResolver(0xA2C122BE93b0074270ebeE7f6b7292C7deB45047); // mainnet

    ITypeface capsulesTypeface =
        ITypeface(0xA77b7D93E79f1E6B4f77FaB29d9ef85733A3D44A); // Capsules typeface
    bytes fontSource = // Capsules font source
        ITypeface(capsulesTypeface).sourceOf(
            Font({weight: 400, style: "normal"})
        );
    IJBFundingCycleStore fundingCycleStore =
        IJBFundingCycleStore(0x6f18cF9173136c0B5A6eBF45f19D58d3ff2E17e6);
    IJBProjects projects =
        IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);
    IJBDirectory directory =
        IJBDirectory(0xCc8f7a89d89c2AB3559f484E0C656423E979ac9C);
    IJBTokenStore tokenStore =
        IJBTokenStore(0x6FA996581D7edaABE62C15eaE19fEeD4F1DdDfE7);
    IJBProjectHandles projectHandles =
        IJBProjectHandles(0xE3c01E9Fd2a1dCC6edF0b1058B5757138EF9FfB6);
    IJBSingleTokenPaymentTerminalStore singleTokenPaymentTerminalStore =
        IJBSingleTokenPaymentTerminalStore(
            0xdF7Ca703225c5da79A86E08E03A206c267B7470C
        );
    IJBController controller =
        IJBController(0xFFdD70C318915879d5192e8a0dcbFcB0285b3C98);

    function getUri(uint256 _projectId)
        external
        view
        override
        returns (string memory tokenUri)
    {
    // Funding Cycle
    // FC#
    JBFundingCycle memory fundingCycle = fundingCycleStore.currentOf(_projectId); // Project's current funding cycle
    uint256 currentFundingCycleId = fundingCycle.number; // Project's current funding cycle id
    // Duration
    uint256 start = fundingCycle.start; // Project's funding cycle start time
    uint256 duration = fundingCycle.duration; // Project's current funding cycle duration
    uint256 timeLeft = start + duration - block.timestamp; // Project's current funding cycle time left
    uint256 timeLeftInDays = timeLeft / 86400; // Project's current funding cycle time left in days //TODO Improve for hours


    IJBPaymentTerminal primaryEthPaymentTerminal = directory.primaryTerminalOf(_projectId, JBTokens.ETH); // Project's primary ETH payment terminal
    uint256 balance = singleTokenPaymentTerminalStore.balanceOf(IJBSingleTokenPaymentTerminal(address(primaryEthPaymentTerminal)),_projectId); // Project's ETH balance //TODO Try/catch    

    uint256 latestConfiguration = fundingCycleStore.latestConfigurationOf(_projectId); // Get project's current FC  configuration 
    
    // Distribution Limit
    string memory distributionLimitCurrency;
    (uint256 distributionLimitPreprocessed, uint256 distributionLimitCurrencyPreprocessed) = controller.distributionLimitOf(_projectId, latestConfiguration, primaryEthPaymentTerminal, JBTokens.ETH); // Project's distribution limit
    if (distributionLimitCurrencyPreprocessed == 1){
        distributionLimitCurrency = "ETH";
    } else {
        distributionLimitCurrency = "USD";
    }
    string memory distributionLimit = string(abi.encodePacked((distributionLimitPreprocessed/10**18).toString(), " ", distributionLimitCurrency)); // Project's distribution limit

    // Supply
    uint256 totalSupply = tokenStore.totalSupplyOf(_projectId)/10**18; // Project's token total supply 
    
    // JBToken ERC20
    IJBToken jbToken = tokenStore.tokenOf(_projectId); 
    bool tokenIssued;
    string memory jbTokenString;
    string memory tokenIssuedString; 
    address jbTokenAddress = address(jbToken);
    if (jbTokenAddress == address(0)){tokenIssued = false;} else {
        tokenIssued = true; 
        jbTokenString = toAsciiString(jbTokenAddress);
    }
    if(tokenIssued){tokenIssuedString = "True";} else {tokenIssuedString = "False";}
    

    // Owner 
    address owner = projects.ownerOf(_projectId); // Project's owner
    string memory ownerName;
    // TODO Use AddressToENSString library (wip) to resolve ENS address onchain
    // try resolver.name(reverseRegistrar.node(owner)) returns (string memory _ownerName) {
    //     ownerName = _ownerName;
    // } catch {
        ownerName = toAsciiString(owner);
    // }

    uint256 overflow =singleTokenPaymentTerminalStore.currentTotalOverflowOf(_projectId,0,1); // Project's overflow to 0 decimals
    
    // Project Handle
    string memory projectName;
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

        string[] memory parts = new string[](4);
        // parts[0] = string("data:application/json;base64,");
        // parts[1] = string(
        //     abi.encodePacked(
        //         '{"name":"',
        //         projectName,
        //         '", "description":"',
        //         projectName,
        //         " is a project on the Juicebox Protocol. It has an overflow of ",
        //         (overflow / 10**18).toString(),
        //         ' ETH.", "image":"data:image/svg+xml;base64,'
        //     )
        // );
        // parts[2] = Base64.encode(
        //     abi.encodePacked(
        //         '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="400" version="1.1"><style>.capsules-400{ white-space: pre; font-family: Capsules-400 } @font-face { font-family: "Capsules-400"; src: url(data:font/truetype;charset=utf-8;base64,',
        //         fontSource,
        //         ') format("opentype")}</style> <rect width="300" height="400" stroke="black" stroke-width="6" fill="#ffaf03"/> <text class="capsules-400" xml:space="preserve" style="font-size:42px;line-height:1;word-spacing:0px;white-space:pre" transform="translate(0,0)"> <tspan x="19" y="52">',
        //         projectName, 
        //         '</tspan> </text> <text class="capsules-400" xml:space="preserve" style="font-size:42.6667px;line-height:1;word-spacing:0px;white-space:pre" transform="translate(0,192)"> <tspan x="19" y="52" style="fill:#ff0000">',
        //         'Overflow </tspan> <tspan x="19" y="96" style="fill:#ff0000">',
        //         (overflow / 10**18).toString(),
        //         "ETH </tspan> </text><text>",
        //         "</text></svg>"
        //     )
        // );
        // parts[3] = string('"}');
        parts[0] = Base64.encode(abi.encodePacked("\nname: ", projectName, "\nbalance: ", balance.toString(), "\noverflow: ", overflow.toString(), "\ndist limit: ", distributionLimit, "\ntotal supply: ", totalSupply.toString(), "\nowner: ", ownerName, "\nFC ", currentFundingCycleId.toString(), "\nDays Left: ", timeLeftInDays, "\nToken Issued: ", tokenIssuedString, "\nToken address: ", jbTokenString, "\n"));
        string memory uri =
            // abi.encodePacked(
                parts[0]
                // Base64.encode(abi.encodePacked(parts[1], parts[2], parts[3]))
            // )
        ;
        return uri;
    }

    

// borrowed from https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
}

function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
}

}
