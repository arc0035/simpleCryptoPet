// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./ERC721.sol";
import "./KittyBase.sol";


contract KittyOwnership is KittyBase, ERC721 {
    /***ERC-165 ***/
    bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 = 
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)'));
        
    function supportsInterface(bytes4 _interfaceID) external view returns (bool){
        return _interfaceID == InterfaceSignature_ERC165 || _interfaceID == InterfaceSignature_ERC721;      
    }

    /***ERC-721***/
    string public constant name = "CryptoKitties";
    string public constant symbol = "CK";
    
    function totalSupply() public view returns (uint256 total){
        return kitties.length;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return ownershipTokenCount[_owner];
    }

    function transfer(address _to, uint256 _tokenId) external whenNotPaused{
        //Misuse
        require(address(0) != _to);
        require(address(this) != _to);

        require(_owns(msg.sender, _tokenId));
        _transfer(msg.sender, _to, _tokenId);
        emit Transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) external whenNotPaused{
        require(address(0) != _to);
        require(address(this) != _to); 

        require(_owns(msg.sender, _tokenId));
        _approve(_to, _tokenId);
        emit Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused{
        require(address(0) != _to);
        require(address(this) != _to);   

        require(_owns(_from, _tokenId));
        require(_approvedFor(msg.sender, _tokenId));
        _transfer(_from, _to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    function ownerOf(uint256 _tokenId) external view returns (address owner){
        owner = kittyIndexToOwner[_tokenId];

        require(owner != address(0));
    } 

    /***Helpers***/
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool){
        return kittyIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool){
        return kittyIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(address _approved, uint256 _tokenId) internal {
        kittyIndexToApproved[_tokenId] = _approved;
    }
}
