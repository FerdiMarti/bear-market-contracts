import { ethers } from 'hardhat';

async function main() {
    // Constants for deployment
    const COLLATERAL_ASSET = '0x...'; // Replace with actual collateral asset address
    const DEBT_ASSET = '0x...'; // Replace with actual debt asset address
    const CDP_MANAGER = '0x...'; // Replace with actual CDP manager address
    const OPTIONS_PROTOCOL = '0x...'; // Replace with actual options protocol address
    const PRICE_ORACLE = '0x...'; // Replace with actual price oracle address

    console.log('Deploying CollarVault...');

    const CollarVault = await ethers.getContractFactory('CollarVault');
    const collarVault = await CollarVault.deploy(COLLATERAL_ASSET, DEBT_ASSET, CDP_MANAGER, OPTIONS_PROTOCOL, PRICE_ORACLE);

    await collarVault.waitForDeployment();

    console.log('CollarVault deployed to:', await collarVault.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
