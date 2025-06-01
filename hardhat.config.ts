import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'dotenv/config';
import './tasks/getUsdc';
import './tasks/checkUsdc';

const config: HardhatUserConfig = {
    solidity: {
        version: '0.8.28',
        settings: {
            viaIR: true,
            optimizer: {
                enabled: true,
                runs: 200,
                details: {
                    yulDetails: {
                        optimizerSteps: 'u',
                    },
                },
            },
        },
    },
    networks: {
        hardhat: {
            chainId: 8453,
            forking: {
                url: 'https://base-mainnet.g.alchemy.com/v2/' + process.env.ALCHEMY_API_KEY, // or Infura, etc.
                enabled: true,
            },
        },
        berachain: {
            url: 'https://rpc.berachain.com',
            accounts: [process.env.BERACHAIN_PRIVATE_KEY as string],
        },
        hedera: {
            url: 'https://testnet.hashio.io/api',
            accounts: [process.env.HEDERA_PRIVATE_KEY as string],
        },
    },
};

export default config;
