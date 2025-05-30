import { task, types } from 'hardhat/config';
import { USED_CONTRACTS } from '../utils/constants';

task('check-usdc', 'Check USDC balance of an address')
    .addOptionalParam('address', 'The address to check (defaults to Account #0)', undefined, types.string)
    .setAction(async taskArgs => {
        // Get Account #0 if no address is provided
        const signers = await ethers.getSigners();
        const targetAddress = taskArgs.address || signers[0].address;

        // Get USDC contract instance
        const usdc = await ethers.getContractAt('IERC20', USED_CONTRACTS.USDC);

        // Get balance
        const balance = await usdc.balanceOf(targetAddress);
        const balanceInUSDC = Number(balance) / 10 ** 6; // Convert from 6 decimals to human readable

        console.log(`USDC Balance for ${targetAddress}${!taskArgs.address ? ' (Account #0)' : ''}: ${balanceInUSDC} USDC`);
    });
