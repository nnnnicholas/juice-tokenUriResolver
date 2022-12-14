// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IJBTokenUriResolver} from "@juicebox/interfaces/IJBTokenUriResolver.sol";
import {IJBProjects} from "@juicebox/interfaces/IJBProjects.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {JBUriOperations} from "./Libraries/JBUriOperations.sol";
import {JBOperatable, IJBOperatorStore} from "@juicebox/abstract/JBOperatable.sol";

/**
 * @title Juicebox TokenUriResolver Registry
 * @notice The registry serves metadata for all Juciebox v2 projects.
 * @dev Projects' default metadata can be updated by the contract owner.
 * @dev Juicebox project owners can override the deafult metadata with their own metadata contracts.
 */
contract TokenUriResolver is IJBTokenUriResolver, JBOperatable, Ownable {
    IJBProjects public immutable projects;
    event DefaultTokenUriResolverSet(IJBTokenUriResolver indexed tokenUriResolver);

    /**
     * @notice Each project's token uri resolver.
     * @dev 0 is the default resolver.
     * @return The address of the token uri resolver for the project, or 0 if none is set.
     */
    mapping(uint256 => IJBTokenUriResolver) public tokenUriResolvers; // projectId => tokenUriResolver

    /**
     * @notice TokenUriResolver constructor.
     * @dev Sets the default token uri resolver. This resolver is used if a project does not have a custom resolver.
     * @param _projects The address of the Juicebox Projects contract.
     * @param _operatorStore The address of the JBOperatorStore contract.
     * @param _defaultTokenUriResolver The address of the default token uri resolver.
     */
    constructor(
        IJBProjects _projects,
        IJBOperatorStore _operatorStore,
        IJBTokenUriResolver _defaultTokenUriResolver
    ) JBOperatable(_operatorStore) {
        projects = _projects;
        tokenUriResolvers[0] = IJBTokenUriResolver(_defaultTokenUriResolver);
    }

    /**
     *  @notice Get the token uri for a project.
     *  @dev Called by `JBProjects.tokenUri(uint256)`. If a project has a custom token uri resolver, it is used instead of the default resolver.
     *  @param _projectId The id of the project.
     *  @return tokenUri The token uri for the project.
     *  @inheritdoc	IJBTokenUriResolver.
     */
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

    /**
     * @notice Set the token uri resolver for a project. Only available to that project's owner and operators.
     * @dev Set the token uri resolver for a project to 0 to use the default resolver.
     * @param _projectId The id of the project.
     * @param _resolver The address of the token uri resolver.
     */
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

    /**
     * @notice Set the default token uri resolver.
     * @dev Only available to the contract owner.
     * @param _resolver The address of the default token uri resolver.
     */
    function setDefaultTokenUriResovler(IJBTokenUriResolver _resolver)
        external
        onlyOwner
    {
        tokenUriResolvers[0] = IJBTokenUriResolver(_resolver);
        emit DefaultTokenUriResolverSet(_resolver);
    }
}
