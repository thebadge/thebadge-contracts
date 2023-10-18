export enum Chains {
  goerli = 5,
  sepolia = 11155111,
  gnosis = 100,
}

export const contracts = {
  TheBadge: {
    address: {
      [Chains.goerli]: "0xF118b243eBBAB8166D23Eb98Ace86fEFdE62A748",
      [Chains.sepolia]: "0x70d6b6cdB3ce3FE21EefE4F967Bb2d8e12E0F701",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeStore: {
    address: {
      [Chains.goerli]: "0x41055729e96661Db8125A114dCDEa6aF55B74523",
      [Chains.sepolia]: "0x156d65224376Aed425A551CD85fCbAa1e56C3568",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeUsers: {
    address: {
      [Chains.goerli]: "0x5Db75bA250eE4B675D9C7627BC11F2BC3b8c099f",
      [Chains.sepolia]: "0x38779E2d51181b461234B85Ee8D49cc2D24F2895",
      [Chains.gnosis]: "",
    },
  },
  TheBadgeModels: {
    address: {
      [Chains.goerli]: "0xBaF92b831Ed905F791355fe9ECF0fce144712bdb",
      [Chains.sepolia]: "0xB7a687C965EF94478FB9a19812086B43A1Ca6ddb",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelController: {
    address: {
      [Chains.goerli]: "0xbCA482008Bfe1ABBF44d451b810911007e5b7764",
      [Chains.sepolia]: "0xF6f544D306C2b56226cC3E771d45F2c21731C739",
      [Chains.gnosis]: "",
    },
  },
  KlerosBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x55cB7227EE660C596d8d4d4BB427F90e3feEB684",
      [Chains.sepolia]: "0x1848F0Ec7dDcCbf6aa8D451A06F3557018e394d0",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelController: {
    address: {
      [Chains.goerli]: "0xE424fD75Dec6DBFAf3782d0A7A0DA23FBFCD91C7",
      [Chains.sepolia]: "0xba689941f0a7b7dE12563987aA5f09B649b55ae1",
      [Chains.gnosis]: "",
    },
  },
  TpBadgeModelControllerStore: {
    address: {
      [Chains.goerli]: "0x883D0927bDB1471bCfC77bB6EbaA334eCfbdC1F5",
      [Chains.sepolia]: "0x87aD3a2EF03804a874Fdf560C18186b2b956D840",
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
