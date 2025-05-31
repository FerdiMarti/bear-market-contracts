type AddressTypes = {
    USDC: string;
    USDC_WHALE: string;
    PYTH: string;
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
            PYTH: '0x8250f4aF4B972684F7b336503E2D6dFeDeB1487a',
        },
    },
};

export const USED_CONTRACTS = CONTRACT_ADDRESSES.BASE.mainnet;
