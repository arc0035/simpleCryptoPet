// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract BasicControl {
    
    //1. Role Access Controll
    address public ceoAddress;

    modifier onlyCLevel() {
        require(msg.sender == ceoAddress);
        _;
    }

    function setCEO(address _ceo) external onlyCLevel {
        ceoAddress = _ceo;
    } 

    //2. Lifecycle Controll
    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() external onlyCLevel whenNotPaused{
        paused = true;
        emit Pause();
    }

    function unpause() external onlyCLevel whenPaused{
        paused = false;
        emit Unpause();
    }
}
