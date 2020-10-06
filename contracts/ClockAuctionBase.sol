// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./ERC721.sol";

contract ClockAuctionBase {


    struct Auction{
        address seller;

        uint128 startingPrice;

        uint128 endingPrice;

        uint64 duration;

        uint64 startedAt;
    }

    ERC721 public nft;

    mapping(uint256=>Auction) public tokenIdToAuction;

    uint256 public ownerCut;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nft.ownerOf(_tokenId) == _claimant);
    }

    //The product is temprorily stored in the contract, and will be released after transaction is decided
    function _escrow(address _owner, uint256 _tokenId) internal {
        nft.transferFrom(_owner, address(this), _tokenId);
    }

    //Move this transaction to the receiver
    function _transfer(address _receiver, uint256 _tokenId) internal {
        nft.transfer(_receiver, _tokenId);
    }

    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(_tokenId, _auction.startingPrice, _auction.endingPrice, _auction.duration);
    }


    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
    }

    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);
        address seller = auction.seller;
        
        uint256 auctioneerCut = _computeCut(price);
        uint256 sellerProceeds = price - auctioneerCut;
        seller.transfer(sellerProceeds);
        uint256 excess = _bidAmount - price;
        msg.sender.transfer(excess);    
        emit AuctionSuccessful(_tokenId, price, msg.sender);
        return price;
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);//Not cancelled, not success
    }

    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondPassed = 0;
        if(now > _auction.startedAt){
            secondPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondPassed
        );        
    }

    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
    internal pure returns (uint256){
        if(_secondsPassed >= _duration){
            return _endingPrice;
        }
        int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
        //128 bit multipli 64 bit wont excess 256 bit
        int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
        int256 currentPrice = int256(_startingPrice) + currentPriceChange;

        return uint256(currentPrice);
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        //Before using safemath, firstly consider does it overflow?
        //_price is actually 128 bit by business. So 2**128 * 10000 does not excess 2**256
        return _price * ownerCut / 10000;
    }

}
