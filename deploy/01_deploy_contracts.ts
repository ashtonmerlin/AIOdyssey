import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const {deployments, getNamedAccounts} = hre;
	const {deploy} = deployments;
	
	const {deployer} = await getNamedAccounts();
	console.log("deployer: ", deployer)

	const signer = "0xFb15f03AE156b409BD06F9ea4CBBf4131aA7A894";

	await deploy('AINFTToken', {from: deployer, args: [], log: true, autoMine: true,});
	const AINFTToken = await hre.ethers.getContract("AINFTToken");
	console.log("AINFTToken deployed to: ", AINFTToken.address);


	await deploy('AIOdysseyNFT', {from: deployer, args: [signer, AINFTToken.address], log: true, autoMine: true,});
	const AIOdysseyNFT = await hre.ethers.getContract("AIOdysseyNFT");
	console.log("AIOdysseyNFT deployed to: ", AIOdysseyNFT.address);

	await AINFTToken.grantMintRole(AIOdysseyNFT.address);
	console.log("Done to grant mint role to AIOdysseyNFT: ", AIOdysseyNFT.address);
};
export default func;
//func.tags = ['AINFTToken'];

