export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0x4e14816A80D7c4FeEeb56C225e821c6374F4AB56",
      [Chains.sepolia]: "0x4e14816A80D7c4FeEeb56C225e821c6374F4AB56",
      [Chains.gnosis]: "0x4e14816A80D7c4FeEeb56C225e821c6374F4AB56",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0x158A8379071d280e811dC7b670c22a0b46dC582D",
      [Chains.sepolia]: "0x158A8379071d280e811dC7b670c22a0b46dC582D",
      [Chains.gnosis]: "0x158A8379071d280e811dC7b670c22a0b46dC582D",
    },
  },
  TheBadgeUsersStore: {
    address: {
      [Chains.goerli]: "0x905a49Ead7540FF8a563EB02F66B5c13c5e8eC71",
      [Chains.sepolia]: "0x905a49Ead7540FF8a563EB02F66B5c13c5e8eC71",
      [Chains.gnosis]: "0x905a49Ead7540FF8a563EB02F66B5c13c5e8eC71",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0xbAaA5510144470eBE7260B743CA5516596A0250E",
      [Chains.sepolia]: "0xbAaA5510144470eBE7260B743CA5516596A0250E",
      [Chains.gnosis]: "0xbAaA5510144470eBE7260B743CA5516596A0250E",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0xDb5c2bcfD8cc522B8DD634DC507E135383049566",
      [Chains.sepolia]: "0xDb5c2bcfD8cc522B8DD634DC507E135383049566",
      [Chains.gnosis]: "0xDb5c2bcfD8cc522B8DD634DC507E135383049566",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0x2C68a077fc4b4e694958A978b409e4127D68f811",
      [Chains.sepolia]: "0x2C68a077fc4b4e694958A978b409e4127D68f811",
      [Chains.gnosis]: "0x2C68a077fc4b4e694958A978b409e4127D68f811",
    },
  },
  KlerosBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x5F7BF602cF2cc5f631C639293CA0bC733eCD31A6",
      [Chains.sepolia]: "0x5F7BF602cF2cc5f631C639293CA0bC733eCD31A6",
      [Chains.gnosis]: "0x5F7BF602cF2cc5f631C639293CA0bC733eCD31A6",
    },
  },
  TpBadgeModelController: {
    address: {
      [Chains.goerli]: "0xB085F625E976c913b82Bf291d32Dc0E55566D3Af",
      [Chains.sepolia]: "0xB085F625E976c913b82Bf291d32Dc0E55566D3Af",
      [Chains.gnosis]: "0xB085F625E976c913b82Bf291d32Dc0E55566D3Af",
    },
  },
  TpBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x9521e582c3d52cF6a8Dd5adc350f66cB0814c281",
      [Chains.sepolia]: "0x9521e582c3d52cF6a8Dd5adc350f66cB0814c281",
      [Chains.gnosis]: "0x9521e582c3d52cF6a8Dd5adc350f66cB0814c281",
    },
  },
  LightGTCRFactory: {
    address: {
      [Chains.goerli]: "0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314",
      [Chains.sepolia]: "0x3FB8314C628E9afE7677946D3E23443Ce748Ac17",
      [Chains.gnosis]: "0x08e58Bc26CFB0d346bABD253A1799866F269805a",
    },
  },
  KlerosArbitror: {
    address: {
      [Chains.goerli]: "0x1128ed55ab2d796fa92d2f8e1f336d745354a77a",
      [Chains.sepolia]: "0x90992fb4e15ce0c59aeffb376460fda4ee19c879",
      [Chains.gnosis]: "0x9C1dA9A04925bDfDedf0f6421bC7EEa8305F9002",
    },
  },
} as const;

export const isSupportedNetwork = (chainId: number): boolean => {
  return chainId in Chains;
};
