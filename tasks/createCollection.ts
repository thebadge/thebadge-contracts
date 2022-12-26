import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

export default task("create-collection", "Create The Badge collection").setAction(
  async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts, ethers } = hre;
    const { deployer } = await getNamedAccounts();

    const TheBadge = await ethers.getContractFactory("TheBadge");
    const collection = await TheBadge.deploy();

    await collection.deployed();
  },
);
