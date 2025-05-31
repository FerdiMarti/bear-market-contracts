import { ethers } from 'hardhat';
import { USED_CONTRACTS } from '../utils/constants';

async function main() {
    // Get the contract factory
    const OptionTokenManager = await ethers.getContractFactory('OptionTokenManager');
    console.log('Deploying OptionTokenManager...');

    // Deploy the contract
    const optionTokenManager = await OptionTokenManager.deploy(USED_CONTRACTS.PYTH);

    // Wait for deployment to finish
    await optionTokenManager.waitForDeployment();

    const address = await optionTokenManager.getAddress();
    console.log(`OptionTokenManager deployed to: ${address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
