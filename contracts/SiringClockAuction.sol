// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./ClockAuction.sol";

contract SiringClockAuction is ClockAuction{

    constructor(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut){}

    //Called by NFT
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external{
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nft));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    //Called by buyer
    function bid(uint256 _tokenId)
        external
        payable
    {
        require(msg.sender == address(nft));
        _bid(_tokenId, msg.value);
    }
}
