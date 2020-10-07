const KittyCore = artifacts.require("KittyCore");

contract("First", async accounts => {
    let instance = await KittyCore.deployed();
    console.log(instance);
    //let balance = await instance.getBalance.call(accounts[0]);
    //assert.equal(balance.valueOf(), 10000);
  });
