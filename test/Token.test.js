const { expect } = require("chai");
const { ethers } = require("hardhat");

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), "ether");
};

describe("Token", () => {
  let token, accounts, deployer;

  beforeEach(async () => {
    // fetch the token from blockchain
    const Token = await ethers.getContractFactory("Token");
    // deploy to the test
    token = await Token.deploy("Sholjum", "SHOL", 1000000);
    // fetch the accounts
    accounts = await ethers.getSigners();
    deployer = accounts[0];
  });

  describe("Deployment", () => {
    const name = "Sholjum";
    const symbol = "SHOL";
    const decimals = 18;
    const totalSupply = tokens(1000000);

    it("has correct name", async () => {
      // eslint-disable-next-line jest/valid-expect
      expect(await token.name()).to.equal(name);
    });

    it("has correct symbol", async () => {
      // eslint-disable-next-line jest/valid-expect
      expect(await token.symbol()).to.equal(symbol);
    });

    it("has correct decimals", async () => {
      // eslint-disable-next-line jest/valid-expect
      expect(await token.decimals()).to.equal(decimals);
    });

    it("has correct total supply", async () => {
      // eslint-disable-next-line jest/valid-expect
      expect(await token.totalSupply()).to.equal(totalSupply);
    });

    it("assigns total supply to deployer", async () => {
      // eslint-disable-next-line jest/valid-expect
      expect(await token.balanceOf(deployer.address)).to.equal(totalSupply);
    });
  });
});
