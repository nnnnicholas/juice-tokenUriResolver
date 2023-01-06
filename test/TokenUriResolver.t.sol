// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TokenUriResolver} from "../src/TokenUriResolver.sol";
import "../src/DefaultTokenUriResolver.sol";
import {JBOperatorData} from "@juicebox/structs/JBOperatorData.sol";

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
            _operatorStore
            ,_directory
            ,_projectHandles
            ,_capsulesTypeface
            // ,_reverseRegistrar
            // ,_resolver
        );

    TokenUriResolver t = new TokenUriResolver(_projects, _operatorStore, d);

    /*//////////////////////////////////////////////////////////////
                         TOKENURIRESOLVER TESTS
    //////////////////////////////////////////////////////////////*/

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

    // Tests that setting a new default resolver works
    function testSetDefaultMetadata() external {
        // Get the default metadata
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
        // Create and set a new default resolver
        DefaultTokenUriResolver n = new DefaultTokenUriResolver(
            _operatorStore
            ,_directory
            ,_projectHandles
            ,_capsulesTypeface
            // ,_reverseRegistrar
            // ,_resolver
        );
        t.setDefaultTokenUriResolver(n);
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

    // Tests that calls to getUri fail when no working resolver is set, and that setting a new default resolver works correctly
    function testGetDefaultMetadata2() external {
        TokenUriResolver x = new TokenUriResolver(
            _projects,
            _operatorStore,
            IJBTokenUriResolver(address(uint160(55)))
        );
        vm.expectRevert();
        string memory z = x.getUri(1);
        assertEq(z, "", "Default metadata should be empty");
        DefaultTokenUriResolver y = new DefaultTokenUriResolver(
            _operatorStore
            ,_directory
            ,_projectHandles
            ,_capsulesTypeface
            // ,_reverseRegistrar
            // ,_resolver
        );
        x.setDefaultTokenUriResolver(y);
        x.getUri(1);
    }

    // Tests that only the TokenUriResolver owner can set the default resolver
    function testSetDefaultTokenUriResolverRequiresOwner() external {
        // Attempt to set default resolver from a non-owner address
        vm.prank(0x1234567890123456789012345678901234567890);
        vm.expectRevert("Ownable: caller is not the owner");
        t.setDefaultTokenUriResolver(IJBTokenUriResolver(address(uint160(55))));
        // Attempt as owner
        t.setDefaultTokenUriResolver(IJBTokenUriResolver(address(uint160(55))));
    }

    // Tests that the default resolver cannot be set via the setTokenUriResolverForProject function
    function testSetTokenUriResolverForProjectCannotSetDefaultResolver()
        external
    {
        // Attempt to set default resolver via setTokenUriResolverForProject
        vm.expectRevert("ERC721: owner query for nonexistent token");
        // vm.expectRevert(TokenUriResolver.Unauthorized.selector); // Will never reach here because the requirePermission call fails first as there is no project with projectId 0
        t.setTokenUriResolverForProject(
            0,
            IJBTokenUriResolver(address(uint160(55)))
        );
    }

    // Tests that addresses that are not owners or operators cannot set a project's custom resolver
    function testSetTokenUriResolverForProjectWithoutPermission(address x)
        external
    {
        // Impersonate a valid non-owner address
        vm.assume(x != address(0));
        vm.assume(x != address(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e));
        assumeNoPrecompiles(x, 1);
        vm.prank(x);
        // Attempt to set custom resolver for a project that address doesn't own
        vm.expectRevert(JBOperatable.UNAUTHORIZED.selector);
        t.setTokenUriResolverForProject(
            1,
            IJBTokenUriResolver(address(uint160(55)))
        );
    }

    // Tests that a project owner can set a custom resolver for their project
    function testSetTokenUriResolverForProjectAsOwner() external {
        // Set a custom resolver for a project as owner
        uint256 projectId = 1;
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        t.setTokenUriResolverForProject(
            projectId,
            IJBTokenUriResolver(address(uint160(55)))
        );
        // Get the custom resolver for the project
        address x = address(t.tokenUriResolvers(projectId));
        assertEq(x, address(uint160(55)), "Custom resolver does not match");
    }

    // Tests that a project operator can set a custom resolver for their project
    function testSetTokenUriResolverForProjectAsOperator() external {
        // Attempt to set a custom resolver for a project as non-operator, non-owner
        uint256 projectId = 1;
        vm.prank(0x1234567890123456789012345678901234567890);
        vm.expectRevert(JBOperatable.UNAUTHORIZED.selector);
        t.setTokenUriResolverForProject(
            projectId,
            IJBTokenUriResolver(address(uint160(55)))
        );
        // Set an operator
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = JBUriOperations.SET_TOKEN_URI;
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        operatorStore.setOperator(
            JBOperatorData({
                operator: 0x1234567890123456789012345678901234567890,
                domain: projectId,
                permissionIndexes: indexes
            })
        );
        // Check operator is set
        assertEq(
            operatorStore.hasPermission(
                0x1234567890123456789012345678901234567890,
                0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e,
                projectId,
                JBUriOperations.SET_TOKEN_URI
            ),
            true,
            "Operator should be set"
        );
        // Set a custom resolver for a project as operator
        vm.prank(0x1234567890123456789012345678901234567890);
        t.setTokenUriResolverForProject(
            1,
            IJBTokenUriResolver(address(uint160(55)))
        );
        // // Check that the custom resolver for the project was set as expected
        address x = address(t.tokenUriResolvers(1));
        assertEq(x, address(uint160(55)), "Custom resolver does not match");
    }

    // Tests that an operator can only modify the resolver for projects they are operators for, and not other projects owned by the same address
    function testSetTokenUriResolverForProjectAsOperatorCorrectDomainOnly()
        external
    {
        // Set an operator
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = JBUriOperations.SET_TOKEN_URI;
        uint256 projectId1 = 273; // https://juicebox.money/v2/p/273
        uint256 projectId2 = 267; // https://juicebox.money/v2/p/267 (owned by the same address at block 16303332)
        address ownerOfTwoProjects = 0x190803C6dF6141a5278844E06420bAa71c622ea4;
        vm.prank(ownerOfTwoProjects); // experiments.daodevinc.eth owns 2 projects
        operatorStore.setOperator(
            JBOperatorData({
                operator: 0x1234567890123456789012345678901234567890,
                domain: projectId1,
                permissionIndexes: indexes
            })
        );
        // Check operator is set
        assertEq(
            operatorStore.hasPermission(
                0x1234567890123456789012345678901234567890,
                ownerOfTwoProjects,
                projectId1,
                JBUriOperations.SET_TOKEN_URI
            ),
            true,
            "Operator should be set"
        );
        // Attempt to set a custom resolver for a project as operator, but for a different project
        vm.prank(0x1234567890123456789012345678901234567890);
        vm.expectRevert(JBOperatable.UNAUTHORIZED.selector);
        t.setTokenUriResolverForProject(
            projectId2,
            IJBTokenUriResolver(address(uint160(55)))
        );
    }

    /*//////////////////////////////////////////////////////////////
                     DEFAULTTOKENURIRESOLVER TESTS
    //////////////////////////////////////////////////////////////*/

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
}
