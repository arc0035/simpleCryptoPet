var GeneScience = artifacts.require('GeneScience');
 
module.exports = function(deployer) {
  // Use deployer to state migration tasks.
  deployer.deploy(GeneScience);
};