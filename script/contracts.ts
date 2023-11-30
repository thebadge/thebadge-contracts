export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
  polygon = 137,
  mumbai = 80001,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0x4e14816A80D7c4FeEeb56C225e821c6374F4AB56",
      [Chains.sepolia]: "0x4e14816A80D7c4FeEeb56C225e821c6374F4AB56",
      [Chains.gnosis]: "0x5f90580636AE29a9E4CD2AFFCE6d73501cD594F2",
    //  [Chains.polygon]: "0x844A31e0E8085Ecc62b9F6f6BEb55f0BdeBBaa4C",
      [Chains.polygon]: "0xC277084C7237a60826844995F4Daec0be690EB9a",
      [Chains.mumbai]: "0xBc8B15322279D7DEDfA6f38EC22075491aEDDB0f",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0x158A8379071d280e811dC7b670c22a0b46dC582D",
      [Chains.sepolia]: "0x158A8379071d280e811dC7b670c22a0b46dC582D",
      [Chains.gnosis]: "0xaDe4Dcc3613dc0b77593adb3D694F2F6f71E4125",
 //     [Chains.polygon]: "0x158A8379071d280e811dC7b670c22a0b46dC582D",
      [Chains.polygon]: "0x942b049df3466a24c9e504c4265edd9f413f3ee2",
      [Chains.mumbai]: "0xfA31e6E50d2Aa260434A056e7CaA3FD582B1FfE8",
    },
  },
  TheBadgeUsersStore: {
    address: {
      [Chains.goerli]: "0x905a49Ead7540FF8a563EB02F66B5c13c5e8eC71",
      [Chains.sepolia]: "0x905a49Ead7540FF8a563EB02F66B5c13c5e8eC71",
      [Chains.gnosis]: "0x9316b09049c432E9F69e7d2f613036d936332Ad1",
      [Chains.polygon]: "0xbAaA5510144470eBE7260B743CA5516596A0250E",
      [Chains.mumbai]: "0x63e00a9aE661CC88620B5F71FE03DaDa958B5096",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0xbAaA5510144470eBE7260B743CA5516596A0250E",
      [Chains.sepolia]: "0xbAaA5510144470eBE7260B743CA5516596A0250E",
      [Chains.gnosis]: "0x8C0DcD187127b88665fE8FD4F39Cb18758946C0f",
      [Chains.polygon]: "0x1D408E53a18dF1C01E51b412Cd60fA3aB11733c3",
      [Chains.mumbai]: "0xAdCd2Cd1249211EeD1D4d72b1E8B53F3A792e5da",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0xDb5c2bcfD8cc522B8DD634DC507E135383049566",
      [Chains.sepolia]: "0xDb5c2bcfD8cc522B8DD634DC507E135383049566",
      [Chains.gnosis]: "0x277D01AACE02C9e6Fa617Ea61Ece24BEDa46453c",
      [Chains.polygon]: "0xF7FAAB24e9fDBC37b270510AdAB45e672eFD5D0d",
      [Chains.mumbai]: "0x3540D8484C5ab270b53e16EDD71791d37A49BBf8",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0x2C68a077fc4b4e694958A978b409e4127D68f811",
      [Chains.sepolia]: "0x2C68a077fc4b4e694958A978b409e4127D68f811",
      [Chains.gnosis]: "0x51e6775fFcDc4E7bd819663E9CabD2bE723C4fBf",
      [Chains.polygon]: "",
      [Chains.mumbai]: "0xfD4403b0A7e39232bADFC188298F4a08AB20A6D9",
    },
  },
  KlerosBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x5F7BF602cF2cc5f631C639293CA0bC733eCD31A6",
      [Chains.sepolia]: "0x5F7BF602cF2cc5f631C639293CA0bC733eCD31A6",
      [Chains.gnosis]: "0x86a3C11F2531cb064A4862d371DCB53793E26437",
      [Chains.polygon]: "0x5F7BF602cF2cc5f631C639293CA0bC733eCD31A6",
      [Chains.mumbai]: "0x942B5f77d8b174B35a9AC2D4b6a609E7ffF3Af56",
    },
  },
  TpBadgeModelController: {
    address: {
      [Chains.goerli]: "0xB085F625E976c913b82Bf291d32Dc0E55566D3Af",
      [Chains.sepolia]: "0xB085F625E976c913b82Bf291d32Dc0E55566D3Af",
      [Chains.gnosis]: "0xDd3472bD0B1382e90238D19b5916C71a657eF223",
      [Chains.polygon]: "0x5F7BF602cF2cc5f631C639293CA0bC733eCD31A6",
      [Chains.mumbai]: "0x323370530CC8481Bb1599d4C9d565053c8BADAb1",
    },
  },
  TpBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x9521e582c3d52cF6a8Dd5adc350f66cB0814c281",
      [Chains.sepolia]: "0x9521e582c3d52cF6a8Dd5adc350f66cB0814c281",
      [Chains.gnosis]: "0x59168cE4F00531D8d86aB1eeBBB670DB537dA8AB",
      [Chains.polygon]: "0x00d7F503531523d446F746387D53BFaa2B0ee182",
      [Chains.mumbai]: "0x76c422969185675Ec46a80B765621B63451cF9F1",
    },
  },
  LightGTCRFactory: {
    address: {
      [Chains.goerli]: "0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314",
      [Chains.sepolia]: "0x3FB8314C628E9afE7677946D3E23443Ce748Ac17",
      [Chains.gnosis]: "0x08e58Bc26CFB0d346bABD253A1799866F269805a",
      [Chains.polygon]: "0xf6740379930fef3a812e00c4a725c8bb10052a1d",
      [Chains.mumbai]: "0xf6740379930fef3a812e00c4a725c8bb10052a1d",
    },
  },
  KlerosArbitror: {
    address: {
      [Chains.goerli]: "0x1128ed55ab2d796fa92d2f8e1f336d745354a77a",
      [Chains.sepolia]: "0x90992fb4e15ce0c59aeffb376460fda4ee19c879",
      [Chains.gnosis]: "0x9C1dA9A04925bDfDedf0f6421bC7EEa8305F9002",
      [Chains.polygon]: "0x0f7aa4776538b83A7Afd4802880512979f7E8F93",
      [Chains.mumbai]: "0x0f7aa4776538b83A7Afd4802880512979f7E8F93",
    },
  },
} as const;

export const isSupportedNetwork = (chainId: number): boolean => {
  return chainId in Chains;
};
