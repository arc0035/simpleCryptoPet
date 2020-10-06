// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;


contract ERC721 {
    //当前系统总共包含了多少只kitty
    function totalSupply() public view returns (uint256 total);
    //当前包含多少只kitty
    function balanceOf(address _owner) public view returns (uint256 balance);
    //把该kitty转移给他人
    function transfer(address _to, uint256 _tokenId) external;
    //将我方某只kitty的转移权授权给他人
    function approve(address _to, uint256 _tokenId) external;
    //将from的某个kitty转移给to，前提是from已经通过approve将操作权授权给操作者msg.sender
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    //查询kitty主人
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    //ERC-165 standard
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}
