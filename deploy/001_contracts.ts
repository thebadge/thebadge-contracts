import * as dotenv from "dotenv";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
// import { execSync } from "child_process";

dotenv.config();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;
  const { deployer } = await hre.ethers.getNamedSigners();
  const deployerOwner = "0x9cf2288d8FA37051970AeBa88E8b4Fb5960c2385";

  //------------------
  // The Badge
  //------------------
  /*
  console.log("Deploying TheBadge...");
  const theBadge = await deployments.deploy("TheBadge", {
    from: deployer.address,
    args: [deployerOwner, deployerOwner],
    // proxy: {
    //   execute: {
    //     methodName: "initialize",
    //     args: [deployerOwner, deployerOwner],
    //   },
    //   proxyContract: "OpenZeppelinTransparentProxy",
    // },
  });
  const theBadgeAddress = theBadge.address;
  console.log("TheBadge:", theBadgeAddress);
*/
  const theBadgeAddress = "0x3CAdA9894F299870CBdBAD5975748D7074a8DbF1";

  //------------------
  // Kleros controller
  //------------------
  console.log("Deploying KlerosBadgeTypeController...");
  /* GBC: */
  //const lightGTCRFactory = "0x08e58Bc26CFB0d346bABD253A1799866F269805a";
  // const klerosArbitror = "0x9C1dA9A04925bDfDedf0f6421bC7EEa8305F9002";
  /* Goerli: */
  const lightGTCRFactory = "0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314";
  const klerosArbitror = "0x1128ed55ab2d796fa92d2f8e1f336d745354a77a";
  const klerosController = await deployments.deploy("KlerosBadgeTypeController", {
    from: deployer.address,
    args: [theBadgeAddress, klerosArbitror, lightGTCRFactory],
    // proxy: {
    //   execute: {
    //     methodName: "initialize",
    //     args: [theBadgeAddress, klerosArbitror, lightGTCRFactory],
    //   },
    //   proxyContract: "OpenZeppelinTransparentProxy",
    // },
  });
  console.log("klerosBadgeTypeController:", klerosController.address);

  // // register controller in TheBadge
  // const TheBadge = await hre.ethers.getContractFactory("TheBadge");
  // const tb = await TheBadge.attach(theBadgeAddress);
  // tb.setBadgeTypeController("kleros", klerosController.address);
  // console.log("TheBadge - set Kleros controller:", klerosController.address);

  // verify contracts
  // console.log("Verifying in etherscan...");
  // execSync(`npx hardhat verify --network goerli ${theBadge.address}`);
  // execSync(`npx hardhat verify --network goerli ${klerosController.address}`);
};

export default func;
