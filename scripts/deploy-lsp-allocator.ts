import { ethers } from 'hardhat';

async function main() {
    // Constants for deployment
    const LSP_ADDRESS = '0x...'; // Replace with actual LSP address
    const OPTION_IMPLEMENTATION = '0x...'; // Replace with actual option implementation address
    const PAYMENT_TOKEN = '0x...'; // Replace with actual payment token address (e.g., NECT)

    console.log('Deploying LSPAllocator...');

    const LSPAllocator = await ethers.getContractFactory('LSPAllocator');
    const lspAllocator = await LSPAllocator.deploy(LSP_ADDRESS, OPTION_IMPLEMENTATION, PAYMENT_TOKEN);

    await lspAllocator.waitForDeployment();

    console.log('LSPAllocator deployed to:', await lspAllocator.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
