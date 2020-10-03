// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./BasicControl.sol";

contract KittyBase is BasicControl {
     /*** EVENTS ***/
    event Birth(address owner, uint256 kittyId, uint256 matronId, uint256 sireId, uint256 genes);

    event Transfer(address from, address to, uint256 tokenId);
    /*** DATA TYPES ***/
    //status for the kitty
    //exactly two 256 bit words. See http://solidity.readthedocs.io/en/develop/miscellaneous.html
    //That is why we move relationship out of struct Kitty
    //Mark for more research
    struct Kitty {
        uint256 genes;

        //timestamp for seconds
        uint64 birthTime;

        uint32 matronId;

        uint32 sireId;

        uint32 sireWithId;

        //(i.e. max(matron.generation, sire.generation) + 1)
        uint16 generation;

        //Starts at floor(generation/2) for others.  Incremented by one for each successful breeding action
        uint16 cooldownIndex;

        uint64 cooldownEndBlock;
    }

    /***CONSTANTS***/
    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

    /***STORAGE***/
    uint256 public secondsPerBlock = 15;

    Kitty[] public kitties;

    mapping(uint256 => address) public kittyIndexToOwner;
    mapping(address =>uint256) public ownershipTokenCount;
    //Allow someone to transfer this kitty to another from owner
    mapping(uint256 => address) public kittyIndexToApproved;
    //Allow someone to breed with this kitty
    mapping(uint256 => address) public sireAllowedToAddress;

    //No condition check. Because this is an internal method. Condition check should be put for external/public
    function _createKitty(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    ) internal returns (uint)
    {
        //Require that data are in actual range
        require(_matronId == uint32(_matronId));
        require(_sireId == uint32(_sireId));
        require(_generation == uint16(_generation));

        //Build a cat and store to kitties
        uint16 cooldownIndex = uint16(_generation / 2);
        if(cooldownIndex > 13) cooldownIndex = 13;
        
        Kitty memory kitty = Kitty({
            genes: _genes,
            birthTime: uint64(now),
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            sireWithId: 0,
            generation: uint16(_generation),
            cooldownIndex: cooldownIndex,
            cooldownEndBlock: 0
        });
        uint256 newKittieId = kitties.push(kitty) - 1;
        require(newKittieId == uint32(newKittieId));
        emit Birth(_owner, newKittieId, _matronId, _sireId, _genes);

        //Init ownership info
        _transfer(address(0), _owner, newKittieId);

        //Return
        return newKittieId;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        kittyIndexToOwner[_tokenId] = _to;
        ownershipTokenCount[_to]++;
        
        if(_from != address(0)){
            ownershipTokenCount[_from]--;
            //clear any previously approved transfer rights
            delete kittyIndexToApproved[_tokenId];
            //once the kitten is transferred also clear sire allowances
            delete sireAllowedToAddress[_tokenId];
        }
        emit Transfer(_from, _to, _tokenId);
    }

    function setSecondsPerBlock(uint256 sec) external onlyCLevel {
        secondsPerBlock = sec;
    }
}
