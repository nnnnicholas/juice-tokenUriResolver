// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract StringSlicer{
    // This function is in a separate contract so that TokenUriResolver can pass it a string memory and we can still use Array Slices (which only work on calldata)
    function slice(string calldata _str, uint _start, uint _end) external pure returns (string memory) {
            return string(bytes(_str)[_start:_end]);
    }
}

contract ContractTest is Test {
    StringSlicer s = new StringSlicer();
    
    function testSlice()external{
        string memory str = "012345";
        assertEq(s.slice(str, 0, 5), "01234");
    }
}