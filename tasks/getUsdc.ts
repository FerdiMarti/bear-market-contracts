import { task, types } from 'hardhat/config';
import { CONTRACT_ADDRESSES } from '../utils/constants';

task('get-usdc', 'Get USDC tokens for testing')
    .addOptionalParam('address', 'The address to receive USDC (defaults to Account #0)', undefined, types.string)
    .addParam('amount', 'Amount of USDC to get (in USDC units, not wei)', undefined, types.int)
    .setAction(async taskArgs => {
        const { amount } = taskArgs;

        // Get Account #0 if no address is provided
        const signers = await ethers.getSigners();
        const recipient = taskArgs.address || signers[0].address;

        // Convert amount to bigint (USDC has 6 decimals)
        const usdcAmount = BigInt(amount) * 10n ** 6n;

        await getUSDC(recipient, usdcAmount);

        console.log(`Successfully transferred ${amount} USDC to ${recipient}${!taskArgs.address ? ' (Account #0)' : ''}`);
    });

async function getUSDC(recipient: string, amount: bigint) {
    // Get USDC contract instance
    const usdc = await ethers.getContractAt('IERC20', CONTRACT_ADDRESSES.BASE.mainnet.USDC);

    // Impersonate the whale account
    await network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [CONTRACT_ADDRESSES.BASE.mainnet.USDC_WHALE],
    });

    // Get the whale signer
    const whaleSigner = await ethers.getSigner(CONTRACT_ADDRESSES.BASE.mainnet.USDC_WHALE);

    // Fund the whale with ETH to pay for gas
    await network.provider.send('hardhat_setBalance', [
        CONTRACT_ADDRESSES.BASE.mainnet.USDC_WHALE,
        '0x' + (1n * 10n ** 18n).toString(16), // 1 ETH
    ]);

    // Transfer USDC from whale to recipient
    await usdc.connect(whaleSigner).transfer(recipient, amount);

    // Stop impersonating the whale
    await network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [CONTRACT_ADDRESSES.BASE.mainnet.USDC_WHALE],
    });
}
