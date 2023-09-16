export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0x76149777Ce10AEd3c39C2D66F0A20E95c4fC2d96",
      [Chains.sepolia]: "0x83701fe7a462bD714A9006a9FF604367C24613E3",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0xcde24aA65c099758a7fd480a258b69Db705B4DA6",
      [Chains.sepolia]: "0x79Ffb85704b223B39d924233A14c849F5A3dC2e2",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0x873a18c9F91a3e4D69B885EA13857848445b87EE",
      [Chains.sepolia]: "0x5E7c648EE852241f145e1d480932C091979883D1",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0xa6aef6A5eA2E94CC72C158513Ae1e350EDcaAd56",
      [Chains.sepolia]: "0x5df8183d0B77Bea3B72391eB0c4c873d2fdDC6f2",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0x66baE30240d7963CA8e5Bc61FA5cd4AbFf4B2F07",
      [Chains.sepolia]: "0x93549ecf683cc80C4aE73e2dbf11cb0FA51bc303",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelController: {
    address: {
      [Chains.goerli]: "0x9F5E64f42fF843dDAd6a5468A489d8591079906A",
      [Chains.sepolia]: "",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x3fa9Dd8F7bB62eECb049a2e94d54Ba8f684bb35e",
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
