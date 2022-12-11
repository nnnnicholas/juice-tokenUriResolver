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
    IJBFundingCycleStore public _fundingCycleStore = IJBFundingCycleStore(0x6f18cF9173136c0B5A6eBF45f19D58d3ff2E17e6);
    IJBProjects public _projects = IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);
    IJBDirectory public _directory = IJBDirectory(0x65572FB928b46f9aDB7cfe5A4c41226F636161ea);
    IJBTokenStore public _tokenStore = IJBTokenStore(0x6FA996581D7edaABE62C15eaE19fEeD4F1DdDfE7);
    IJBSingleTokenPaymentTerminalStore public _singleTokenPaymentTerminalStore = IJBSingleTokenPaymentTerminalStore(0xdF7Ca703225c5da79A86E08E03A206c267B7470C);
    IJBController public _controller = IJBController(0xFFdD70C318915879d5192e8a0dcbFcB0285b3C98);
    IJBOperatorStore public _operatorStore = IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);
    IJBProjectHandles public _projectHandles = IJBProjectHandles(0xE3c01E9Fd2a1dCC6edF0b1058B5757138EF9FfB6);
    ITypeface public _capsulesTypeface  = ITypeface(0xA77b7D93E79f1E6B4f77FaB29d9ef85733A3D44A);
    IReverseRegistrar public _reverseRegistrar = IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);
    IResolver public _resolver = IResolver(0xA2C122BE93b0074270ebeE7f6b7292C7deB45047);

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
}
