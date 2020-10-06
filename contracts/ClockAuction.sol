// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./Pausable.sol";
import "./ClockAuctionBase.sol";

contract ClockAuction is Pausable, ClockAuctionBase{
    
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    constructor (address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 nftContract = ERC721(_nftAddress);
        require(nftContract.supportsInterface(InterfaceSignature_ERC721));
        nft = nftContract;
    }

    function withdrawBalance() external {
        address nftAddress = address(nft);

        require(msg.sender == nftAddress || msg.sender == owner);
        //owner和nft地址应该是同一个地址
        nftAddress.transfer(address(this).balance);
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration)
    external whenNotPaused{
        require(_startingPrice == uint128(_startingPrice));
        require(_endingPrice == uint128(_endingPrice));
        require(_duration == uint64(_duration));

        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);

        Auction memory auction = Auction(
            msg.sender,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    function bid(uint256 _tokenId) external payable whenNotPaused{
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    function cancelAuction(uint256 _tokenId) external{
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }


    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }    
}
