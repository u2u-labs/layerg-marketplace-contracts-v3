import { ethers, run } from "hardhat";
import { writeFileSync } from "fs";
import { join } from "path";
import { ZeroAddress } from "ethers";

async function main() {
  console.log("Starting deployment process...");

  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.log(`Deploying contracts with the account: ${deployerAddress}`);

  console.log("Deploying Marketplace contract...");
  const MarketplaceContractFactory = await ethers.getContractFactory(
    "Marketplace"
  );
  const feeRecipient = "0x2743eEC46576f76f47334569074242F3D9a90B44";
  const assetTransferAgent = "0x87c0Bd922322C149D4110992b44282BE6bc6a1C1";
  const feeBps = 500;
  const Marketplace = await MarketplaceContractFactory.deploy(
    feeRecipient,
    assetTransferAgent,
    feeBps
  );
  await Marketplace.waitForDeployment();
  const marketplaceAddress = await Marketplace.getAddress();
  console.log(`Marketplace deployed to: ${marketplaceAddress}`);
  await run("verify:verify", {
    address: marketplaceAddress,
    constructorArguments: [ZeroAddress, ZeroAddress, 500],
  });
  console.log("Marketplace verified successfully");

  const deploymentData = {
    contractAddress: marketplaceAddress,
    network: (await ethers.provider.getNetwork()).name,
    deployer: deployerAddress,
    timestamp: new Date().toISOString(),
  };

  const deploymentsDir = join(__dirname, "..", "deployments");
  const filePath = join(
    deploymentsDir,
    `deployment-marketplace-${deploymentData.network}.json`
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
