import { HardhatRuntimeEnvironment } from 'hardhat/types';

declare global {
    const network: HardhatRuntimeEnvironment['network'];
    const ethers: HardhatRuntimeEnvironment['ethers'];
    // Common Hardhat objects
    const artifacts: HardhatRuntimeEnvironment['artifacts'];
    // Config
    const config: HardhatRuntimeEnvironment['config'];
}

export {}; // Make this a module
