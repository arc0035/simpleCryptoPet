// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;


import "./ClockAuction.sol";

contract SaleClockAuction is ClockAuction {
    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

    constructor(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut){}


    //Called by NFT(eth cat)
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
        require(msg.sender == address(nft));
        require(_startingPrice == uint128(_startingPrice));
        require(_endingPrice == uint128(_endingPrice));
        require(_duration == uint64(_duration));
        
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
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        //原生猫只能由NFT售卖，而非先挖掘到某账户手中，由账户售卖。官卖
        if(seller == address(nft)){
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }
}
