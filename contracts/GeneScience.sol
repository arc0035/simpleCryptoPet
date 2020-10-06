// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./GeneScienceInterface.sol";

contract GeneScience is GeneScienceInterface{

    constructor() public{}
    uint256 private constant maskLast8Bit = uint256(0xff);
    uint256 private constant maskFirst248Bit = uint256(~0xff);
    event Random(uint256 randomN);
    /***Externals***/
    function mixGenes(uint256 _genes1, uint256 _genes2, uint256 _targetBlock) public returns(uint256){
        
        uint256 randomN = uint256(blockhash(_targetBlock));
        //0 means the current block. So we found some previous block. 
        if(randomN == 0) {
            _targetBlock = (block.number & maskFirst248Bit) + (_targetBlock & maskLast8Bit);
            if(_targetBlock > block.number){
                _targetBlock -= 0xff;
            }
            randomN = uint256(blockhash(_targetBlock)); 
        }
        
        //As much entrophy as we can
        randomN = uint256(keccak256(randomN, _genes1, _genes2, _targetBlock));
        emit Random(randomN);
        uint8[] memory traits1 = _toTraits(_genes1);
        uint8[] memory traits2 = _toTraits(_genes2);
        uint8[] memory baby = new uint8[](48);
        uint rIndex = 0;
        uint8 swap;
        //Horitzon swap
        uint rand;
        for(uint i = 0;i<12;i++){
            for(uint j=3;j>=1;j--){
                uint traitId = (i * 4) + j;
                rand = _sliceInteger(randomN, 2, rIndex);
                rIndex += 2;
                if(rand == 0){
                    swap = traits1[traitId - 1];
                    traits1[traitId - 1] = traits1[traitId];
                    traits1[traitId] = swap;                   
                }
                rand = _sliceInteger(randomN, 2, rIndex);
                rIndex += 2;
                if(rand == 0){
                    swap = traits2[traitId - 1];
                    traits2[traitId - 1] = traits2[traitId];
                    traits2[traitId] = swap;                   
                }
            }
        }
        //Vertical chosen
        for(i=0;i<48;i++){
            rand = _sliceInteger(randomN, 1, rIndex);
            rIndex += 1;   

            if(rand == 0){
                baby[i] =  traits1[i];
            }
            else{
                baby[i] =  traits2[i];
            }
        }
        return 1;
        //return _fromTraits(baby);
        
    }

    function expressingTraits(uint256 _genes) public pure returns(uint8[12] memory) {
        uint8[12] memory result;
        for(uint i=0;i<12;i++){
            result[i] = uint8(_sliceInteger(_genes, 5, i*20));
        }
        return result;
    }

    function encode(uint8[] memory _traits) public pure returns (uint256 _genes) {
        return _fromTraits(_traits);
    }

    function decode(uint256 _genes) public pure returns(uint8[] memory) {
        return _toTraits(_genes);
    }
    
    /***Internals***/
    function _toTraits(uint256 _genes) internal pure returns (uint8[] memory) {
        uint8[] memory result = new uint8[](48);
        uint offset = 0;
        for(uint i=0;i<48;i++){
            result[i] = uint8(_sliceInteger(_genes, 5, offset));
            offset+=5;
        }
        return result;
    }

    function _fromTraits(uint8[] memory _traits) internal pure returns (uint256 _genes) {
        _genes = 0;
        for(uint i=0;i<48;i++){
            _genes <<= 5;
            _genes |= _traits[47 - i];
        }
    }

    function _sliceInteger(uint256 _val, uint256 _nbits, uint256 _offset) internal pure returns(uint256){
        uint256 mask = (1 << _nbits) - 1;
        mask <<= _offset;  
        _val &= mask;
        _val >>= _offset;
        return _val;
    }
}
