// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IJBTokenUriResolver} from "@juicebox/interfaces/IJBTokenUriResolver.sol";
import {IJBProjects} from "@juicebox/interfaces/IJBProjects.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {JBUriOperations} from "./Libraries/JBUriOperations.sol";
import {JBOperatable, IJBOperatorStore} from "@juicebox/abstract/JBOperatable.sol";

/**
 * @title Juicebox TokenUriResolver Registry
 * @notice The registry serves metadata for all Juciebox Protocol v2 projects.
 * @dev The default metadata for all projects can be updated by the contract owner.
 * @dev Juicebox project owners can override the default metadata for their project with their own IJBTokenUriResolver contracts.
 */
contract TokenUriResolver is IJBTokenUriResolver, JBOperatable, Ownable {
    IJBProjects public immutable projects;
    event DefaultTokenUriResolverSet(
        IJBTokenUriResolver indexed tokenUriResolver
    );
    event ProjectTokenUriResolverSet(
        uint256 indexed projectId,
        IJBTokenUriResolver indexed tokenUriResolver
    );
    error Unauthorized();

    /**
     * @notice Each project's IJBTokenUriResolver metadata contract.
     * @dev Mapping of projectId => tokenUriResolver
     * @dev The 0 project returns the default resolver's address.
     * @return IJBTokenUriResolver The address of the IJBTokenUriResolver for the project, or 0 if none is set.
     */
    mapping(uint256 => IJBTokenUriResolver) public tokenUriResolvers;

    /**
     * @notice TokenUriResolver constructor.
     * @dev Sets the default IJBTokenUriResolver. This resolver is used for all projects that do not have a custom resolver.
     * @param _projects The address of the Juicebox Projects contract.
     * @param _operatorStore The address of the JBOperatorStore contract.
     * @param _defaultTokenUriResolver The address of the default IJBTokenUriResolver.
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
     *  @dev Called by `JBProjects.tokenUri(uint256)`. If a project has a custom IJBTokenUriResolver, it is used instead of the default resolver.
     *  @param _projectId The id of the project.
     *  @return tokenUri The token uri for the project.
     *  @inheritdoc	IJBTokenUriResolver
     */
    function getUri(uint256 _projectId)
        external
        view
        override
        returns (string memory tokenUri)
    {
        IJBTokenUriResolver tur = tokenUriResolvers[_projectId];
        if (tur == IJBTokenUriResolver(address(0))) {
            return tokenUriResolvers[0].getUri(_projectId);
        } else {
            try tur.getUri(_projectId) returns (
                string memory uri
            ) {
                return uri;
            } catch {
                return tokenUriResolvers[0].getUri(_projectId);
            }
        }
    }

    /**
     * @notice Set the IJBTokenUriResolver for a project. This function is restricted to the project's owner and operators.
     * @dev Set the IJBTokenUriResolver for a project to 0 to use the default resolver.
     * @param _projectId The id of the project.
     * @param _resolver The address of the IJBTokenUriResolver, or 0 to restore the default setting.
     */
    function setTokenUriResolverForProject(
        uint256 _projectId,
        IJBTokenUriResolver _resolver
    )
        external
        requirePermission(
            projects.ownerOf(_projectId),
            _projectId,
            JBUriOperations.SET_TOKEN_URI
        )
    {
        if (_projectId == 0) revert Unauthorized();
        if (_resolver == IJBTokenUriResolver(address(0))) {
            delete tokenUriResolvers[_projectId];
        } else {
            tokenUriResolvers[_projectId] = _resolver;
        }
        emit ProjectTokenUriResolverSet(_projectId, _resolver);
    }

    /**
     * @notice Set the default IJBTokenUriResolver.
     * @dev Only available to this contract's owner.
     * @param _resolver The address of the default token uri resolver.
     */
    function setDefaultTokenUriResolver(IJBTokenUriResolver _resolver)
        external
        onlyOwner
    {
        tokenUriResolvers[0] = IJBTokenUriResolver(_resolver);
        emit DefaultTokenUriResolverSet(_resolver);
    }
}
