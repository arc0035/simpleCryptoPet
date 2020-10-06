// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./KittyOwnership.sol";
import "./GeneScienceInterface.sol";

contract KittyBreeding is KittyOwnership{

    uint256 public autoBirthFee = 2 finney;
    uint256 public pregnantKitties;


    /***Externals***/
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 cooldownEndBlock);

    GeneScienceInterface public geneScience;

    function setGeneScienceInterface(address geneScienceContract) external onlyCLevel{
        geneScience = GeneScienceInterface(geneScienceContract);
    }

    function setAutoBirthFee(uint256 val) external onlyCLevel{
        autoBirthFee = val;
    }

    function approveSiring(address _addr, uint256 _sireId) external whenNotPaused {
        require(_owns(msg.sender, _sireId));
        sireAllowedToAddress[_sireId] = _addr;
    }

    function breedWithAuto(uint256 _matronId, uint256 _sireId) external payable whenNotPaused {
        require(msg.value >= autoBirthFee);
        require(_matronId > 0 && _sireId > 0);

        require(_owns(msg.sender, _matronId));
        require(_isSiringPermitted(_sireId, _matronId));
        
        Kitty storage matron = kitties[_matronId];
        require(_isReadyToBreed(matron));
        Kitty storage sire = kitties[_sireId];  
        require(_isReadyToBreed(sire));

        _breedWith(_matronId, _sireId);
    }

    function giveBirth(uint256 _matronId) external whenNotPaused returns(uint256) {
        Kitty storage matron = kitties[_matronId];
        require(_isPregnant(matron));
        uint256 sireId = matron.sireWithId;
        Kitty storage sire = kitties[sireId];
        uint256 parentGeneration = matron.generation > sire.generation ? matron.generation: sire.generation;
        //Only after cooldown the matron can give birth to the baby
        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes, matron.cooldownEndBlock - 1);
        address owner = kittyIndexToOwner[_matronId];
        _createKitty(_matronId, sireId, parentGeneration + 1, childGenes, owner);
        pregnantKitties--;
        delete matron.sireWithId ;
        msg.sender.transfer(autoBirthFee);//Anyone can give birth and earn fee!!
    }

    /***Internals***/
    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        Kitty storage matron = kitties[_matronId];
        Kitty storage sire = kitties[_sireId];

        matron.sireWithId = uint32(_sireId);
        
        _triggerCooldown(matron);
        _triggerCooldown(sire);

        //Each pregnant needs allowence.But what if two cats are same owner?
        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];
        
        pregnantKitties++;
        emit Pregnant(kittyIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock);
    }

    function _triggerCooldown(Kitty storage kitty) internal {
        uint32 cooldownTime = cooldowns[kitty.cooldownIndex];
        uint256 cooldownToBlock = (cooldownTime / secondsPerBlock) + block.number;
        kitty.cooldownEndBlock = uint64(cooldownToBlock);
        if (kitty.cooldownIndex < 13) {
            kitty.cooldownIndex += 1;
        }
    }

    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns(bool) {
        address matronOwner = kittyIndexToOwner[_matronId];
        address sireOwner = kittyIndexToOwner[_sireId];

        return matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner;
    }

    function _isReadyToBreed(Kitty storage kitty) internal view returns(bool) {
        return kitty.sireWithId == 0 && kitty.cooldownEndBlock < block.number;
    } 

    function _isPregnant(Kitty storage kitty) internal view returns(bool) {
        return kitty.sireWithId > 0;
    }

    function _isValidMatingPair(
        Kitty storage _matron,
        uint256 _matronId,
        Kitty storage _sire,
        uint256 _sireId
    )
        private
        view
        returns(bool)
    {
        // A Kitty can't breed with itself!
        if (_matronId == _sireId) {
            return false;
        }

        // Kitties can't breed with their parents.
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        // We can short circuit the sibling check (below) if either cat is
        // gen zero (has a matron ID of zero).
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        // Kitties can't breed with full or half siblings.
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        // Everything seems cool! Let's get DTF.
        return true;
    }

}