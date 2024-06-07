export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
  polygon = 137,
  mumbai = 80001,
  avax = 43114,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0x4e14816A80D7c4FeEeb56C225e821c6374F4AB56",
      [Chains.sepolia]: "0x4e14816A80D7c4FeEeb56C225e821c6374F4AB56",
      [Chains.gnosis]: "0x5f90580636AE29a9E4CD2AFFCE6d73501cD594F2",
      [Chains.polygon]: "0xE6c5c3174439DA7D2D60456Ca7eB97E7Dcd551e6",
      [Chains.mumbai]: "0xBc8B15322279D7DEDfA6f38EC22075491aEDDB0f",
      [Chains.avax]: "",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0x158A8379071d280e811dC7b670c22a0b46dC582D",
      [Chains.sepolia]: "0x158A8379071d280e811dC7b670c22a0b46dC582D",
      [Chains.gnosis]: "0xaDe4Dcc3613dc0b77593adb3D694F2F6f71E4125",
      [Chains.polygon]: "0x870cDfe4c9b4FFe0687b7f871f6e96793440B214",
      [Chains.mumbai]: "0xfA31e6E50d2Aa260434A056e7CaA3FD582B1FfE8",
      [Chains.avax]: "",
    },
  },
  TheBadgeUsersStore: {
    address: {
      [Chains.goerli]: "0x905a49Ead7540FF8a563EB02F66B5c13c5e8eC71",
      [Chains.sepolia]: "0x905a49Ead7540FF8a563EB02F66B5c13c5e8eC71",
      [Chains.gnosis]: "0x9316b09049c432E9F69e7d2f613036d936332Ad1",
      [Chains.polygon]: "0x7808B0320a21851139207EdAaAAfb1dc4039ceC2",
      [Chains.mumbai]: "0x63e00a9aE661CC88620B5F71FE03DaDa958B5096",
      [Chains.avax]: "",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0xbAaA5510144470eBE7260B743CA5516596A0250E",
      [Chains.sepolia]: "0xbAaA5510144470eBE7260B743CA5516596A0250E",
      [Chains.gnosis]: "0x8C0DcD187127b88665fE8FD4F39Cb18758946C0f",
      [Chains.polygon]: "0x8Edfc741aED6B2C43485983d4C7b6B095b00500c",
      [Chains.mumbai]: "0xAdCd2Cd1249211EeD1D4d72b1E8B53F3A792e5da",
      [Chains.avax]: "",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0xDb5c2bcfD8cc522B8DD634DC507E135383049566",
      [Chains.sepolia]: "0xDb5c2bcfD8cc522B8DD634DC507E135383049566",
      [Chains.gnosis]: "0x277D01AACE02C9e6Fa617Ea61Ece24BEDa46453c",
      [Chains.polygon]: "0x3C838b8571c53D29108F69b98145f8FcC446Fa5a",
      [Chains.mumbai]: "0x3540D8484C5ab270b53e16EDD71791d37A49BBf8",
      [Chains.avax]: "",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0x2C68a077fc4b4e694958A978b409e4127D68f811",
      [Chains.sepolia]: "0x2C68a077fc4b4e694958A978b409e4127D68f811",
      [Chains.gnosis]: "0x51e6775fFcDc4E7bd819663E9CabD2bE723C4fBf",
      [Chains.polygon]: "0x5B7A6B423246df397daA10f416E42ebff63d0Bc4",
      [Chains.mumbai]: "0xfD4403b0A7e39232bADFC188298F4a08AB20A6D9",
      [Chains.avax]: "",
    },
  },
  KlerosBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x5F7BF602cF2cc5f631C639293CA0bC733eCD31A6",
      [Chains.sepolia]: "0x5F7BF602cF2cc5f631C639293CA0bC733eCD31A6",
      [Chains.gnosis]: "0x86a3C11F2531cb064A4862d371DCB53793E26437",
      [Chains.polygon]: "0xE7f5dE2dafc9B5Fc954C1b800D82E7868EdF2c07",
      [Chains.mumbai]: "0x942B5f77d8b174B35a9AC2D4b6a609E7ffF3Af56",
      [Chains.avax]: "",
    },
  },
  TpBadgeModelController: {
    address: {
      [Chains.goerli]: "0xB085F625E976c913b82Bf291d32Dc0E55566D3Af",
      [Chains.sepolia]: "0xB085F625E976c913b82Bf291d32Dc0E55566D3Af",
      [Chains.gnosis]: "0xDd3472bD0B1382e90238D19b5916C71a657eF223",
      [Chains.polygon]: "0x4dC5E2FaC3D0254fEF7f40163261b9307c1C9df3",
      [Chains.mumbai]: "0x323370530CC8481Bb1599d4C9d565053c8BADAb1",
      [Chains.avax]: "",
    },
  },
  TpBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x9521e582c3d52cF6a8Dd5adc350f66cB0814c281",
      [Chains.sepolia]: "0x9521e582c3d52cF6a8Dd5adc350f66cB0814c281",
      [Chains.gnosis]: "0x59168cE4F00531D8d86aB1eeBBB670DB537dA8AB",
      [Chains.polygon]: "0x46d5469385C4Af4a3dd858AA839fc49d1f6c485f",
      [Chains.mumbai]: "0x76c422969185675Ec46a80B765621B63451cF9F1",
      [Chains.avax]: "",
    },
  },
  LightGTCRFactory: {
    address: {
      [Chains.goerli]: "0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314",
      [Chains.sepolia]: "0x3FB8314C628E9afE7677946D3E23443Ce748Ac17",
      [Chains.gnosis]: "0x08e58Bc26CFB0d346bABD253A1799866F269805a",
      [Chains.polygon]: "0xf6740379930fef3a812e00c4a725c8bb10052a1d",
      [Chains.mumbai]: "0xf6740379930fef3a812e00c4a725c8bb10052a1d",
      [Chains.avax]: "",
    },
  },
  CustomLightGTCRFactory: {
    address: {
      [Chains.goerli]: "",
      [Chains.sepolia]: "0x5B7A6B423246df397daA10f416E42ebff63d0Bc4",
      [Chains.gnosis]: "",
      [Chains.polygon]: "",
      [Chains.mumbai]: "",
      [Chains.avax]: "0x905a49Ead7540FF8a563EB02F66B5c13c5e8eC71",
    },
  },
  CustomLightGTCR: {
    address: {
      [Chains.goerli]: "",
      [Chains.sepolia]: "0xE7f5dE2dafc9B5Fc954C1b800D82E7868EdF2c07",
      [Chains.gnosis]: "",
      [Chains.polygon]: "",
      [Chains.mumbai]: "",
      [Chains.avax]: "0x158A8379071d280e811dC7b670c22a0b46dC582D",
    },
  },
  KlerosArbitror: {
    address: {
      [Chains.goerli]: "0x1128ed55ab2d796fa92d2f8e1f336d745354a77a",
      [Chains.sepolia]: "0x90992fb4e15ce0c59aeffb376460fda4ee19c879",
      [Chains.gnosis]: "0x9C1dA9A04925bDfDedf0f6421bC7EEa8305F9002",
      [Chains.polygon]: "0x0f7aa4776538b83A7Afd4802880512979f7E8F93",
      [Chains.mumbai]: "0x0f7aa4776538b83a7afd4802880512979f7e8f93",
      [Chains.avax]: "",
    },
  },
} as const;

export const isSupportedNetwork = (chainId: number): boolean => {
  return chainId in Chains;
};
