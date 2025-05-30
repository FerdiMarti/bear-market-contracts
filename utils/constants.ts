type AddressTypes = {
    USDC: string;
    USDC_WHALE: string;
};

export const CONTRACT_ADDRESSES: {
    [chain: string]: {
        mainnet: AddressTypes;
        testnet?: AddressTypes;
    };
} = {
    BASE: {
        mainnet: {
            USDC: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
            USDC_WHALE: '0x0B0A5886664376F59C351ba3f598C8A8B4D0A6f3',
        },
    },
};

export const USED_CONTRACTS = CONTRACT_ADDRESSES.BASE.mainnet;
