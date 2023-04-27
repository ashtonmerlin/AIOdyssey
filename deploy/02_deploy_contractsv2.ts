import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const {deployments, getNamedAccounts} = hre;
	const {deploy} = deployments;
	
	const {deployer} = await getNamedAccounts();
	console.log("deployer: ", deployer)

	const signer = "0xFb15f03AE156b409BD06F9ea4CBBf4131aA7A894";

	// await deploy('AINFTToken', {from: deployer, args: [], log: true, autoMine: true,});
	const AINFTToken = await hre.ethers.getContract("AINFTToken");
	console.log("AINFTToken deployed to: ", AINFTToken.address);


	await deploy('AIOdysseyNFTV2', {from: deployer, args: [signer, AINFTToken.address], log: true, autoMine: true,});
	const AIOdysseyNFTV2 = await hre.ethers.getContract("AIOdysseyNFTV2");
	console.log("AIOdysseyNFTV2 deployed to: ", AIOdysseyNFTV2.address);

	await AINFTToken.grantMintRole(AIOdysseyNFTV2.address);
	console.log("Done to grant mint role to AIOdysseyNFT: ", AIOdysseyNFTV2.address);

	await AIOdysseyNFTV2.setBaseURI("https://oasis-server-global.oss-us-west-1.aliyun.com/AIOdyssey/");
	console.log("Done to set base URI to: ", await AIOdysseyNFTV2.baseURI());
};
export default func;
//func.tags = ['AINFTToken'];

