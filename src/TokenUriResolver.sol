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

contract StringSlicer{
    // This function is in a separate contract so that TokenUriResolver can pass it a string memory and we can still use Array Slices (which only work on calldata)
    function slice(string calldata _str, uint _start, uint _end) external pure returns (string memory) {
            return string(bytes(_str)[_start:_end]);
    }
}

contract TokenUriResolver is IJBTokenUriResolver
{
    using Strings for uint256;

    StringSlicer slice = new StringSlicer();

    IReverseRegistrar reverseRegistrar = IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148); // mainnet
    IResolver resolver = IResolver(0xA2C122BE93b0074270ebeE7f6b7292C7deB45047); // mainnet

    ITypeface capsulesTypeface =
        ITypeface(0xA77b7D93E79f1E6B4f77FaB29d9ef85733A3D44A); // Capsules typeface
    bytes fontSource = ITypeface(capsulesTypeface).sourceOf(Font({weight: 500, style: "normal"})); // Capsules font source

    IJBFundingCycleStore fundingCycleStore =
        IJBFundingCycleStore(0x6f18cF9173136c0B5A6eBF45f19D58d3ff2E17e6);
    IJBProjects projects =
        IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);
    IJBDirectory directory =
        IJBDirectory(0x65572FB928b46f9aDB7cfe5A4c41226F636161ea);
    IJBTokenStore tokenStore =
        IJBTokenStore(0x6FA996581D7edaABE62C15eaE19fEeD4F1DdDfE7);
    IJBProjectHandles projectHandles =
        IJBProjectHandles(0xE3c01E9Fd2a1dCC6edF0b1058B5757138EF9FfB6);
    IJBSingleTokenPaymentTerminalStore singleTokenPaymentTerminalStore =
        IJBSingleTokenPaymentTerminalStore(0xdF7Ca703225c5da79A86E08E03A206c267B7470C);
    IJBController controller =
        IJBController(0xFFdD70C318915879d5192e8a0dcbFcB0285b3C98);

    /// @notice Transform strings to target length by abbreviation or left padding with spaces.
    /// @dev Shortens long strings to 13 characters including an ellipsis and adds left padding spaces to short strings. Allows variable target length to account for strings that have unicode characters that are longer than 1 byte but only take up 1 character space.
    /// @param str The string to transform
    /// @param targetLength The length of the string to return
    /// @return string The transformed string
    function pad(bool left, string memory str, uint targetLength) internal view returns (string memory) {
        uint length = bytes(str).length;
        if(left){ // Left pad
            if(length>targetLength){ // Shorten strings strings longer than target length
                str = string(abi.encodePacked(slice.slice(str,0,targetLength-1), unicode'…')); // Shortens to 1 character less than target length and adds an ellipsis unicode character
            } else if (length == targetLength){
                return str;
                } else { // Pad strings shorter than target length
                string memory padding;
                for(uint i=0; i<=targetLength-length; i++){
                    padding = string.concat(padding, ' ');
                }
                str = string.concat(padding, str);
            }
            return str;
        } else { // Right pad
            if(length>targetLength){
                str = string(abi.encodePacked(slice.slice(str,0,targetLength-1), unicode'…')); // Shortens to 1 character less than target length and adds an ellipsis unicode character
            } else if (length == targetLength){
                return str;
                } else {
                    string memory padding;
                    for(uint i=0; i<=targetLength-length; i++){
                        padding = string.concat(padding, ' ');
                    }
                    str = string.concat(str, padding);
                }
            return str;
        }
    }

    function getProjectName(uint256 _projectId) internal view returns(string memory projectName){
    // Project Handle
    string memory projectName;
        // If handle is set
        if (
            keccak256(abi.encode(projectHandles.handleOf(_projectId))) !=
            keccak256(abi.encode(string("")))
        ) {
            // Set projectName to handle
            projectName = string(abi.encodePacked("@", projectHandles.handleOf(_projectId)));
        } else {
            // Set projectName to name to 'Project #projectId'
            projectName = string(
                abi.encodePacked("Project #", _projectId.toString())
            );
        }
        // Abbreviate handle to 27 chars if longer
        if (bytes(projectName).length > 26) {
            projectName = string(abi.encodePacked(slice.slice(projectName, 0, 26), unicode"…"));
        }
        return projectName;        
    }

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
    string memory fundingCycleIdString = currentFundingCycleId.toString();
    string memory paddedFCRight = pad(false, string.concat(unicode'  ꜰc ', fundingCycleIdString), 14 + bytes(fundingCycleIdString).length);
    // Time Left
    uint256 start = fundingCycle.start; // Project's funding cycle start time
    uint256 duration = fundingCycle.duration; // Project's current funding cycle duration
    uint256 timeLeft;
    string memory paddedTimeLeft;
    string memory countString;
    if(duration == 0){ 
        paddedTimeLeft = string.concat(pad(true, string.concat(unicode' ɴoᴛ sᴇᴛ'), 21), '  '); // If the funding cycle has no duration, show infinite duration //  = 3, N = 2, T = 3, E = 3, T = 3
    } else{
        timeLeft = start + duration - block.timestamp; // Project's current funding cycle time left
        if(timeLeft > 2 days){
            countString = (timeLeft/ 1 days).toString();
            paddedTimeLeft = string.concat(pad(true, string.concat(unicode'', ' ', countString, unicode' ᴅᴀʏs'), 18 + bytes(countString).length), '  '); // ᴅ = 3, ᴀ = 3, ʏ = 2
        } else if(timeLeft > 2 hours){
            countString = (timeLeft/ 1 hours).toString(); // 12 bytes || 8 visual + countString
            paddedTimeLeft = string.concat(pad(true, string.concat(unicode'', ' ', countString, unicode' ʜouʀs'), 14 + bytes(countString).length), '  '); // ʜ = 2, ʀ = 2
        } else if(timeLeft > 2 minutes){
            countString = (timeLeft/ 1 minutes).toString();
            paddedTimeLeft = string.concat(pad(true, string.concat(unicode'', ' ', countString, unicode' ᴍɪɴuᴛᴇs'), 21 + bytes(countString).length), '  '); // ᴍ = 3, ɪ = 2, ɴ = 2, ᴛ = 3, ᴇ = 3
        } else {
            countString =  (timeLeft/ 1 seconds).toString();
            paddedTimeLeft = string.concat(pad(true, string.concat(unicode'', ' ', countString, unicode' sᴇcoɴᴅs'), 18 + bytes(countString).length), '  '); // E = 3, ɴ = 2, D = 3
        }
    }

    IJBPaymentTerminal primaryEthPaymentTerminal = directory.primaryTerminalOf(_projectId, JBTokens.ETH); // Project's primary ETH payment terminal
    
    // Balance
    uint256 balance = singleTokenPaymentTerminalStore.balanceOf(IJBSingleTokenPaymentTerminal(address(primaryEthPaymentTerminal)),_projectId)/10**18; // Project's ETH balance //TODO Try/catch    
    string memory paddedBalanceLeft = string.concat(pad(true, string.concat(unicode'Ξ',balance.toString()),13),'  '); // Project's ETH balance as a string
    string memory paddedBalanceRight = pad(false,unicode'  ʙᴀʟᴀɴcᴇ     ', 23); // ʙ = 2, ᴀ = 3, ʟ = 2, ᴀ = 3, ɴ = 2, E = 3
    
    // Distribution Limit
    uint256 latestConfiguration = fundingCycleStore.latestConfigurationOf(_projectId); // Get project's current FC  configuration 
    string memory distributionLimitCurrency;
    (uint256 distributionLimitPreprocessed, uint256 distributionLimitCurrencyPreprocessed) = controller.distributionLimitOf(_projectId, latestConfiguration, primaryEthPaymentTerminal, JBTokens.ETH); // Project's distribution limit
    if (distributionLimitCurrencyPreprocessed == 1){
        distributionLimitCurrency = unicode'Ξ';
    } else {
        distributionLimitCurrency = '$';
    }
    string memory distributionLimit = string.concat(distributionLimitCurrency, (distributionLimitPreprocessed/10**18).toString()); // Project's distribution limit
    string memory paddedDistributionLimitLeft = string.concat(pad(true,distributionLimit,11+bytes(distributionLimitCurrency).length), '  ');
    string memory paddedDistributionLimitRight = string.concat(pad(false, unicode'  ᴅɪsᴛʀ. ʟɪᴍɪᴛ', 27)); // ᴅ = 3, ɪ = 2, T = 3, ʀ = 2, ʟ = 2, ɪ = 2, ᴍ = 3, ɪ = 2, T = 3

    // Supply
    uint256 totalSupply = tokenStore.totalSupplyOf(_projectId)/10**18; // Project's token total supply 
    string memory paddedTotalSupplyLeft = string.concat(pad(true,totalSupply.toString(),12),'  '); // Project's token total supply as a string
    string memory paddedTotalSupplyRight = pad(false,unicode'  ᴛoᴛᴀʟ suᴘᴘʟʏ',27);

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
        ownerName = string.concat('0x', slice.slice(toAsciiString(owner), 0,4),unicode'…', slice.slice(toAsciiString(owner),36,40)); // Abbreviate owner address
    // }

    string memory projectOwnerPaddedRight = pad(false, unicode'  ᴘʀoᴊᴇcᴛ owɴᴇʀ', 28);

    uint256 overflow = singleTokenPaymentTerminalStore.currentTotalOverflowOf(_projectId,0,1); // Project's overflow to 0 decimals
    string memory overflowString = string.concat(unicode'Ξ',overflow.toString());
    string memory paddedOverflowLeft = string.concat(pad(true,overflowString,13), '  '); // Length of 14 because Ξ counts as 2 characters, but has character width of 1
    string memory paddedOverflowRight = string.concat(pad(false,unicode'  ovᴇʀꜰʟow    ', 20)); //  E = 3, ʀ = 2, ꜰ = 3, ʟ = 2



    string memory projectName = getProjectName(_projectId);


        string[] memory parts = new string[](4);
        parts[0] = string("data:application/json;base64,");
        parts[1] = string(
            abi.encodePacked(
                '{"name":"',
                projectName,
                '", "description":"',
                projectName,
                " is a project on the Juicebox Protocol. It has an overflow of ",
                overflowString,
                ' ETH.", "image":"data:image/svg+xml;base64,'
            )
        );
        // Each line (row) of the SVG is 30 monospaced characters long
        // The first half of each line (15 chars) is the title
        // The second half of each line (15 chars) is the value
        // The first and last characters on the line are two spaces
        // The first line (header) is an exception. 
        parts[2] = Base64.encode(
            abi.encodePacked(
                '<svg width="289" height="403" viewBox="0 0 289 403" xmlns="http://www.w3.org/2000/svg"><style>@font-face{font-family:"Capsules-500";src:url(data:font/truetype;charset=utf-8;base64,',
                fontSource, // import Capsules typeface
                ');format("opentype");}a,a:visited,a:hover{fill:inherit;text-decoration:none;}text{font-size:16px;fill:#FF9213;font-family:"Capsules-500",monospace;font-weight:500;white-space:pre-wrap;}#header text{fill:#642617;}</style><g clip-path="url(#clip0_150_56)"><path d="M289 0H0V403H289V0Z" fill="url(#paint0_linear_150_56)"/><rect width="289" height="22" fill="#FF9213"/><g id="header"><a href="https://juicebox.money/v2/p/',
                _projectId.toString(),
                '">',// Line 0: Header
                '<text x="16" y="16">',
                projectName,
                '</text></a><a href="https://juicebox.money"><text x="257" y="16">',unicode'','</text></a></g>',
                // Line 1: FC + Time left
                '<g filter="url(#filter1_d_150_56)"><text x="0" y="48">',
                paddedFCRight,
                paddedTimeLeft,
                '</text>',
                // Line 2: Spacer
                '<text x="0" y="64">',
                unicode'                              ',
                '</text>',
                // Line 3: Balance  
                '<text x="0" y="80">',
                paddedBalanceRight,
                paddedBalanceLeft, //TODO not working
                '</text>',
                // Line 4: Overflow
                '<text x="0" y="96">',
                paddedOverflowRight,
                paddedOverflowLeft, // TODO not working  
                '</text>',
                // Line 5: Distribution Limit
                '<text x="0" y="112">',
                paddedDistributionLimitRight,
                paddedDistributionLimitLeft,
                '</text>',
                // Line 6: Total Supply 
                '<text x="0" y="128">',
                paddedTotalSupplyRight,
                paddedTotalSupplyLeft,
                '</text>',
                // Line 7: Project Owner
                '<text x="0" y="144">',
                projectOwnerPaddedRight,
                '  ', // additional spaces hard coded for this line, presumes address is 11 chars long
                '<a href="https://etherscan.io/address/', toAsciiString(owner), '">',
                ownerName,
                '</a>',
                '</text></g></g><defs><filter id="filter0_d_150_56" x="15.8275" y="0.039999" width="256.164" height="21.12" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset/><feGaussianBlur stdDeviation="2"/><feComposite in2="hardAlpha" operator="out"/><feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 0.572549 0 0 0 0 0.0745098 0 0 0 0.68 0"/><feBlend mode="normal" in2="BackgroundImageFix" result="effect1_dropShadow_150_56"/><feBlend mode="normal" in="SourceGraphic" in2="effect1_dropShadow_150_56" result="shape"/></filter><filter id="filter1_d_150_56" x="-3.36" y="26.04" width="294.539" height="126.12" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset/><feGaussianBlur stdDeviation="2"/><feComposite in2="hardAlpha" operator="out"/> <feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 0.572549 0 0 0 0 0.0745098 0 0 0 0.68 0"/><feBlend mode="normal" in2="BackgroundImageFix" result="effect1_dropShadow_150_56"/><feBlend mode="normal" in="SourceGraphic" in2="effect1_dropShadow_150_56" result="shape"/></filter><linearGradient id="paint0_linear_150_56" x1="0" y1="202" x2="289" y2="202" gradientUnits="userSpaceOnUse"><stop stop-color="#3A0F0C"/><stop offset="0.119792" stop-color="#44190F"/><stop offset="0.848958" stop-color="#43190F"/><stop offset="1" stop-color="#3A0E0B"/></linearGradient><clipPath id="clip0_150_56"><rect width="289" height="403" /></clipPath></defs></svg>'
            )
        );
        parts[3] = string('"}');
        // parts[4] = Base64.encode(abi.encodePacked("\nname: ", projectName, "\nbalance: ", balance.toString(), "\noverflow: ", overflow.toString(), "\ndist limit: ", distributionLimit, "\ntotal supply: ", totalSupply.toString(), "\nowner: ", ownerName, "\nFC ", currentFundingCycleId.toString(), "\nDays Left: ", timeLeftInDays.toString(), "\nToken Issued: ", tokenIssuedString, "\nToken address: ", jbTokenString, "\n"));
        string memory uri =
                string.concat(parts[0], Base64.encode(abi.encodePacked(parts[1], parts[2], parts[3])));
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
