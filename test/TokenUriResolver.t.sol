// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TokenUriResolver} from "../src/TokenUriResolver.sol";
import "../src/DefaultTokenUriResolver.sol";

contract ContractTest is Test {
    // TokenUriResolver constructor args
    IJBProjects public projects =
        IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);
    IJBOperatorStore public operatorStore =
        IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);

    // DefaultTokenUriResolver constructor args
    IJBFundingCycleStore public _fundingCycleStore =
        IJBFundingCycleStore(0x6f18cF9173136c0B5A6eBF45f19D58d3ff2E17e6);
    IJBProjects public _projects =
        IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);
    IJBDirectory public _directory =
        IJBDirectory(0x65572FB928b46f9aDB7cfe5A4c41226F636161ea);
    IJBTokenStore public _tokenStore =
        IJBTokenStore(0x6FA996581D7edaABE62C15eaE19fEeD4F1DdDfE7);
    IJBSingleTokenPaymentTerminalStore public _singleTokenPaymentTerminalStore =
        IJBSingleTokenPaymentTerminalStore(
            0xdF7Ca703225c5da79A86E08E03A206c267B7470C
        );
    IJBController public _controller =
        IJBController(0xFFdD70C318915879d5192e8a0dcbFcB0285b3C98);
    IJBOperatorStore public _operatorStore =
        IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);
    IJBProjectHandles public _projectHandles =
        IJBProjectHandles(0xE3c01E9Fd2a1dCC6edF0b1058B5757138EF9FfB6);
    ITypeface public _capsulesTypeface =
        ITypeface(0xA77b7D93E79f1E6B4f77FaB29d9ef85733A3D44A);
    IReverseRegistrar public _reverseRegistrar =
        IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);
    IResolver public _resolver =
        IResolver(0xA2C122BE93b0074270ebeE7f6b7292C7deB45047);

    DefaultTokenUriResolver d =
        new DefaultTokenUriResolver(
            _fundingCycleStore,
            _projects,
            _directory,
            _tokenStore,
            _singleTokenPaymentTerminalStore,
            _controller,
            _operatorStore,
            _projectHandles,
            _capsulesTypeface,
            _reverseRegistrar,
            _resolver
        );

    TokenUriResolver t = new TokenUriResolver(_projects, _operatorStore, d);

    // Tests that the default resolver works correctly
    function testGetDefaultMetadata() external {
        string memory x = t.getUri(1);
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./open.js";
        inputs[2] = x;
        // bytes memory res = vm.ffi(inputs);
        vm.ffi(inputs);
    }

    // Tests that project owners can set themes on the default resolver and they render correctly when called from the tokenUriResolver.
    function testSetTheme() external {
        Theme memory customTheme = Theme({
            projectId: 1,
            textColor: "white",
            bgColor: "black",
            bgColorDark: "black"
        });
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        d.setTheme(customTheme);
        string memory x = t.getUri(1); // 1, 311, 305, 308, 323
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./open.js";
        inputs[2] = x;
        // bytes memory res = vm.ffi(inputs);
        vm.ffi(inputs);
    }

    // Tests that setting a new default resolver works
    function testSetDefaultMetadata() external {
        string memory defaultMetadata = t.getUri(1);
        // Set a theme on the original resolver
        Theme memory customTheme = Theme({
            projectId: 1,
            textColor: "white",
            bgColor: "black",
            bgColorDark: "black"
        });
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        d.setTheme(customTheme);
        // Set a new default resolver
        DefaultTokenUriResolver n = new DefaultTokenUriResolver(
            _fundingCycleStore,
            _projects,
            _directory,
            _tokenStore,
            _singleTokenPaymentTerminalStore,
            _controller,
            _operatorStore,
            _projectHandles,
            _capsulesTypeface,
            _reverseRegistrar,
            _resolver
        );
        t.setDefaultTokenUriResovler(n);
        assertEq(
            t.getUri(1),
            defaultMetadata,
            "New default metadata does not match"
        );
        // Get metadata from the new resolver
        string memory x = t.getUri(1);
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./open.js";
        inputs[2] = x;
        // bytes memory res = vm.ffi(inputs);
        vm.ffi(inputs);
    }

    function testGetDefaultMetadata2() external {
        TokenUriResolver x = new TokenUriResolver(_projects, _operatorStore, IJBTokenUriResolver(address(uint160(1))));
        // try and catch to call getUri() 
        DefaultTokenUriResolver y = new DefaultTokenUriResolver(
            _fundingCycleStore,
            _projects,
            _directory,
            _tokenStore,
            _singleTokenPaymentTerminalStore,
            _controller,
            _operatorStore,
            _projectHandles,
            _capsulesTypeface,
            _reverseRegistrar,
            _resolver
        ); 
        vm.expectRevert();
        string memory z = x.getUri(1);
        assertEq(z, "", "Default metadata should be empty");
        t.setDefaultTokenUriResovler(y);
    }
}
