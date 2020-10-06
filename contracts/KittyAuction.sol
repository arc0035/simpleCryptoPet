// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./KittyBreeding.sol";
import "./SaleClockAuction.sol";
import "./SiringClockAuction.sol";

contract KittyAuction is KittyBreeding {
    SaleClockAuction public saleAuction;
    SiringClockAuction public siringAuction;
    
    function setSaleAuctionAddress(address _address) external onlyCLevel {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        saleAuction = candidateContract;
    }

    function setSiringAuctionAddress(address _address) external onlyCLevel {
        SiringClockAuction candidateContract = SiringClockAuction(_address);
        siringAuction = candidateContract;
    }   

    function createSaleAuction(
        uint256 _kittyId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _kittyId));
        _approve(address(this), _kittyId);
        saleAuction.createAuction(
            _kittyId,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            msg.sender
        );
    }

    function bidOnSaleAuction(uint256 _kittyId) external payable whenNotPaused{
        uint256 currentPrice = saleAuction.getCurrentPrice(_kittyId);
        require(msg.value >= currentPrice);
    
        saleAuction.bid.value(msg.value)(_kittyId);
        _transfer(address(this), msg.sender, _kittyId);
        msg.sender.transfer(msg.value - currentPrice);
    }


    function createSiringAuction(
        uint256 _kittyId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _kittyId));
        Kitty storage kitty = kitties[_kittyId];
        require(_isReadyToBreed(kitty));
        _approve(address(this), _kittyId);
        siringAuction.createAuction(
            _kittyId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
        external
        payable
        whenNotPaused
    {
        // Auction contract checks input sizes
        require(_owns(msg.sender, _matronId));
        Kitty storage matron = kitties[_matronId];
        require(_isReadyToBreed(matron));

        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);
        
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _transfer(address(this), kittyIndexToOwner[_sireId], _sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
        msg.sender.transfer(msg.value - currentPrice - autoBirthFee);
    }

    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }     
}
