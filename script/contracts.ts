export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0x92E22069c8e12EFe6d9A14EB1bf8301D56Bc168f",
      [Chains.sepolia]: "0x83701fe7a462bD714A9006a9FF604367C24613E3",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0xA13203Eec70a245E1Cb3AD3f3f636e41dD12c0cD",
      [Chains.sepolia]: "0x79Ffb85704b223B39d924233A14c849F5A3dC2e2",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0x4F12622326B25E2AF7043C1caC250988E28Fc737",
      [Chains.sepolia]: "0x5E7c648EE852241f145e1d480932C091979883D1",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0x848f6D6a7A53BAC4b9543CC10FBCA99F39c47468",
      [Chains.sepolia]: "0x5df8183d0B77Bea3B72391eB0c4c873d2fdDC6f2",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0xfA3e24678C42a0E7cd6967DDE9b4c077c45C4Cb4",
      [Chains.sepolia]: "0x93549ecf683cc80C4aE73e2dbf11cb0FA51bc303",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelController: {
    address: {
      [Chains.goerli]: "0xD3914675F46278C10c699b30804220252467F7d9",
      [Chains.sepolia]: "",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0xAd480d38cce9B15245E38838FDf20FB5c0592486",
      [Chains.sepolia]: "",
      [Chains.gnosis]: "",
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
