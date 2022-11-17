// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// This function is in a separate contract so that TokenUriResolver can pass it a string memory and we can still use Array Slices (which only work on calldata)
contract StringSlicer {
    function slice(
        string calldata _str,
        uint256 _start,
        uint256 _end
    ) external pure returns (string memory) {
        return string(bytes(_str)[_start:_end]);
    }
}

contract ContractTest is Test {
    StringSlicer slice = new StringSlicer();

    function testLeftPadShorter() external {
        string memory str = "test";
        string memory res = leftPad(str, 10);
        assertEq(bytes(res).length, 10);
    }

    function testLeftPadShorterUnicode() external {
        string memory str = unicode"";
        string memory res = leftPad(str, 10);
        assertEq(bytes(res).length, 10);
    }

    // Ellipsis is 3 bytes
    // Capsules' Juicebox is
    function testUnicodeByteCount() external {
        // console.log(bytes(unicode'…').length);
        assertEq(bytes(unicode"…").length, 3);
        assertEq(bytes(unicode"").length, 3);
    }

    // Anticipates 2 extra bytes bc unicode ellipsis is 3 bytes
    function testLeftPadLonger() external {
        string memory str = "testing a very long string";
        string memory res = leftPad(str, 10);
        console.log(res);
        assertEq(bytes(res).length, 12);
    }

    // Anticipates 2 extra bytes bc unicode Capsules' Juicebox is 3 bytes
    function testLeftPadLongerUnicode() external {
        string memory str = unicode" testing a very long string";
        string memory res = leftPad(str, 10);
        assertEq(bytes(res).length, 12);
    }

    // Copied leftPad fn here bc it's an internal fn
    function leftPad(string memory str, uint256 targetLength)
        internal
        view
        returns (string memory)
    {
        uint256 length = bytes(str).length;
        if (length > targetLength) {
            // Shorten strings strings longer than target length
            str = string(
                abi.encodePacked(
                    slice.slice(str, 0, targetLength - 1),
                    unicode"…"
                )
            ); // Shortens to 1 character less than target length and adds an ellipsis unicode character
        } else {
            // Pad strings shorter than target length
            string memory padding;
            for (uint256 i = 0; i < targetLength - length; i++) {
                padding = string(abi.encodePacked(padding, " "));
            }
            str = string.concat(padding, str);
        }
        return str;
    }
}
