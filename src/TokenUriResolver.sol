// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IJBTokenUriResolver} from "@juicebox/interfaces/IJBTokenUriResolver.sol";
import {IJBProjects} from "@juicebox/interfaces/IJBProjects.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {JBUriOperations} from "./Libraries/JBUriOperations.sol";
import {JBOperatable, IJBOperatorStore} from "@juicebox/abstract/JBOperatable.sol";

contract TokenUriResolver is IJBTokenUriResolver, JBOperatable, Ownable {
    IJBProjects public immutable projects;
    // IJBOperatorStore public immutable operatorStore;
    mapping(uint256 => IJBTokenUriResolver) public tokenUriResolvers;

    constructor(
        IJBProjects _projects,
        IJBOperatorStore _operatorStore,
        IJBTokenUriResolver _defaultTokenUriResolver
    ) JBOperatable(_operatorStore) {
        projects = _projects;
        tokenUriResolvers[0] = IJBTokenUriResolver(_defaultTokenUriResolver);
    }

    function getUri(uint256 _projectId)
        external
        view
        override
        returns (string memory tokenUri)
    {
        if (tokenUriResolvers[_projectId] == IJBTokenUriResolver(address(0))) {
            return tokenUriResolvers[0].getUri(_projectId);
        } else {
            try tokenUriResolvers[_projectId].getUri(_projectId) returns (
                string memory uri
            ) {
                return uri;
            } catch {
                return tokenUriResolvers[0].getUri(_projectId);
            }
        }
    }

    function setTokenUriResolverForProject(
        uint256 _projectId,
        IJBTokenUriResolver _resolver
    )
        external
        requirePermission(
            projects.ownerOf(_projectId),
            1,
            JBUriOperations.SET_TOKEN_URI
        )
    {
        if (_resolver == IJBTokenUriResolver(address(0))) {
            delete tokenUriResolvers[_projectId];
        } else {
            tokenUriResolvers[_projectId] = _resolver;
        }
    }

    function setDefaultTokenUriResovler(IJBTokenUriResolver _resolver)
        external
        onlyOwner
    {
        tokenUriResolvers[0] = IJBTokenUriResolver(_resolver);
    }
}
