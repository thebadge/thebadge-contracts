export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0x2f2f14FB89129a6E9D4d01E3D29a408Af4A868Bb",
      [Chains.sepolia]: "0x83701fe7a462bD714A9006a9FF604367C24613E3",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0xdD313a032A0F833158F9c89e67950444cC4e1C01",
      [Chains.sepolia]: "0x79Ffb85704b223B39d924233A14c849F5A3dC2e2",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0x9d9284C4c34A280DCae6aA8946c4133140ABA62A",
      [Chains.sepolia]: "0x5E7c648EE852241f145e1d480932C091979883D1",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0x25AB0275Fff77dC085257d8FD817ca14Aa42E5a3",
      [Chains.sepolia]: "0x5df8183d0B77Bea3B72391eB0c4c873d2fdDC6f2",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0x9a2d2777af64478B370A3beF58612F147fFC9b12",
      [Chains.sepolia]: "0x93549ecf683cc80C4aE73e2dbf11cb0FA51bc303",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelController: {
    address: {
      [Chains.goerli]: "0x8b4b38716B0C64DA8763E5630Ad0ea3Db5961178",
      [Chains.sepolia]: "",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x758b938e9726Ea59aaEEe386bbac1e73317bE6BF",
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
