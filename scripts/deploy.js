const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Simple Land Registry...");

  // Deploy the contract
  const SimpleLandRegistry = await ethers.getContractFactory("SimpleLandRegistry");
  const landRegistry = await SimpleLandRegistry.deploy();

  await landRegistry.deployed();

  console.log("SimpleLandRegistry deployed to:", landRegistry.address);
  
  // Add a verifier (example)
  const [deployer] = await ethers.getSigners();
  console.log("Adding deployer as verifier...");
  
  const tx = await landRegistry.addVerifier(deployer.address);
  await tx.wait();
  
  console.log("Deployer added as verifier");
  console.log("Deployment complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });