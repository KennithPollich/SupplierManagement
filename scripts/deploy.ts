import { ethers } from "hardhat";

async function main() {
  console.log("Deploying SupplierManagement contract...");

  // Get the ContractFactory and Signers here.
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy the contract
  const SupplierManagement = await ethers.getContractFactory("SupplierManagement");
  const supplierManagement = await SupplierManagement.deploy();

  await supplierManagement.deployed();

  console.log("SupplierManagement contract deployed to:", supplierManagement.address);
  console.log("Transaction hash:", supplierManagement.deployTransaction.hash);

  // Verify the deployment
  console.log("Verifying deployment...");
  const supplierCount = await supplierManagement.getSupplierCount();
  console.log("Initial supplier count:", supplierCount.toString());

  console.log("\n🎉 Deployment completed successfully!");
  console.log("📝 Update your frontend contract address to:", supplierManagement.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });