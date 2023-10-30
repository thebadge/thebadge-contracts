export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0x5709c7f13FE36487Ebd2ed072AC9A0F43c33e86E",
      [Chains.sepolia]: "0xeCc0B0B2715bc6b6a0E42Eb9A7139aE28A360045",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0xd7d393d49DD4119522A848F18808BB71ca7F7c8B",
      [Chains.sepolia]: "0x269512362c7C0E635f82d2bb14f203F8777A61D0",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0xdea84c826f3A191b150F606be1428427Dd69b2fc",
      [Chains.sepolia]: "0x593664b3ed9cA81b3ED09ED8001c3aCE4898af6A",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0xF856D5729C0608e65Bf6B9E294729BaBBa10586d",
      [Chains.sepolia]: "0x38eA08318DD2D580E6f50F3c98Fb159B05D6261E",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0x87d36e534C4503402EC966f82AB7267cda5d1313",
      [Chains.sepolia]: "0x0a00ed545739FcCB2a116e40e86c9B5D1e8e62f4",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0xd8B98CCe134dc336Eb9f992663c99b29c338323e",
      [Chains.sepolia]: "0x6854a34ee046BFdd611fe9893C504482df280964",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelController: {
    address: {
      [Chains.goerli]: "0x29d213F72Ea469Cbbd8294755B0501bff846Ba1d",
      [Chains.sepolia]: "0xAcEEe7d487401E43bA2ca90c242F43573f9cC3a8",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x83c72827350e54D5Cb679Dd3cc47053944fA3b53",
      [Chains.sepolia]: "0x9A9b2dcE95e843E112b882150A70C9BB8980F099",
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
