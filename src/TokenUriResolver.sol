// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IJBTokenUriResolver} from "@juicebox/interfaces/IJBTokenUriResolver.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract TokenUriResolver is JBTokenUriResolver, Ownable{

    mapping (uint256 => IJBTokenUriResolver) public tokenUriResolvers;

    constructor(IJBTokenUriResolver defaultTokenUriResolver){
        tokenUri[0] = address(defaultTokenUriResolver);
    }

    function getUri(uint256 _projectId) external view override returns (string memory tokenUri){
        if (tokenUriResolvers[_projectId] == IJBTokenUriResolver(address(0))){
            return getDefaultUri(_projectId);
        } else {
            try tokenUriResolvers[_projectId].getUri(_projectId) returns (string memory uri){
                return uri;
            } catch {
                return getDefaultUri(_projectId);
            }
        }
    }

    function setTokenUriResolverForProject(uint256 _projectId, IJBTokenUriResolver _resolver) external requirePermission(projects.ownerOf(_projectId), _projectId, JBUriOperations.SET_TOKEN_URI) { 
        if(_resolver == IJBTokenUriResolver(address(0))){
            delete tokenUriResolvers[_projectId];
        } else {
            tokenUriResolvers[_projectId]= _resolver;
        }
    }

    function setDefaultTokenUriResovler(IJBTokenUriResolver _resolver) external onlyOwner {
        tokenUri[0] = address(_resolver);
    }

}