import { ethers, run } from "hardhat";
import { writeFileSync } from "fs";
import { join } from "path";
import { ZeroAddress } from "ethers";

async function main() {
  console.log("Starting deployment process...");

  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deploying contracts with the account: ${deployerAddress}`);

  console.log("Deploying AssetTransferAgent contract...");
  const AssetTransferAgentContractFactory = await ethers.getContractFactory(
    "AssetTransferAgent"
  );
  const assetTransferAgent = await AssetTransferAgentContractFactory.deploy();
  await assetTransferAgent.waitForDeployment();
  const assetTransferAgentAddress = await assetTransferAgent.getAddress();
  console.log(`AssetTransferAgent deployed to: ${assetTransferAgentAddress}`);
  await run("verify:verify", {
    address: assetTransferAgentAddress,
    constructorArguments: [],
  });
  console.log("AssetTransferAgent verified successfully");

  const deploymentData = {
    contractAddress: assetTransferAgentAddress,
    network: (await ethers.provider.getNetwork()).name,
    deployer: deployerAddress,
    timestamp: new Date().toISOString(),
  };

  const deploymentsDir = join(__dirname, "..", "deployments");
  const filePath = join(
    deploymentsDir,
    `deployment-AssetTransferAgent-${deploymentData.network}.json`
  );

  try {
    writeFileSync(filePath, JSON.stringify(deploymentData, null, 2));
    console.log(`Deployment information saved to ${filePath}`);
  } catch (error) {
    console.error("Failed to save deployment information:", error);
  }

  console.log("Deployment completed successfully!");
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
