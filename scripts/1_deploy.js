const { ethers } = require("hardhat");

async function main() {
  console.log("Preparing deployment... \n");

  // fetch contract to deploy
  const Token = await ethers.getContractFactory("Token");
  const Exchange = await ethers.getContractFactory("Exchange");

  // fetch accounts
  const accounts = await ethers.getSigners();
  console.log(
    `accounts fetched:\n${accounts[0].address}\n${accounts[1].address}\n`
  );

  // deploy the contracts
  const shol = await Token.deploy("Sholjum", "SHOL", "1000000");
  await shol.deployed();
  console.log("SHOL deployed to:", shol.address);

  const sUSD = await Token.deploy("sUSD", "sUSD", "1000000");
  await sUSD.deployed();
  console.log("sUSD deployed to:", sUSD.address);

  const sETH = await Token.deploy("sETH", "sETH", "1000000");
  await sETH.deployed();
  console.log("sETH deployed to:", sETH.address);

  // deploy the exchange
  const exchange = await Exchange.deploy(accounts[1].address, 10);
  await exchange.deployed();
  console.log("exchange deployed to:", exchange.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
