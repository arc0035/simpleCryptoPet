// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./KittyMinting.sol";
import "./GeneScience.sol";

contract KittyCore is KittyMinting{
    /// @notice Creates the main CryptoKitties smart contract instance.
    function KittyCore() public {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        saleAuction = new SaleClockAuction(address(this), 10);
        siringAuction = new SiringClockAuction(address(this), 10);

        geneScience = new GeneScience();
        // start with the mythical kitten 0 - so we don't have generation-0 parent issues
        _createKitty(0, 0, 0, uint256(-1), address(0));
    }


    function getKitty(uint256 _id)
        external
        view
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    ) {
        Kitty storage kit = kitties[_id];

        // if this variable is 0 then it's not gestating
        isGestating = (kit.sireWithId != 0);
        isReady = (kit.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(kit.cooldownIndex);
        nextActionAt = uint256(kit.cooldownEndBlock);
        siringWithId = uint256(kit.sireWithId);
        birthTime = uint256(kit.birthTime);
        matronId = uint256(kit.matronId);
        sireId = uint256(kit.sireId);
        generation = uint256(kit.generation);
        genes = kit.genes;
    }


    function withdrawBalance() external onlyCLevel {
        uint256 balance = address(this).balance;
        // Subtract all the currently pregnant kittens we have, plus 1 of margin.
        uint256 subtractFees = (pregnantKitties + 1) * autoBirthFee;

        if (balance > subtractFees) {
            msg.sender.transfer(balance - subtractFees);
        }
    }
}
