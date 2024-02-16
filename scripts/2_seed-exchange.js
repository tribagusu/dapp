const { ethers } = require("hardhat");
const config = require("../src/config.json");

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), "ether");
};

const wait = (seconds) => {
  const milliseconds = seconds * 1000;
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
};

async function main() {
  // fetch accounts from wallet - these are unlocked
  const accounts = await ethers.getSigners();

  // fetch network
  const { chainId } = await ethers.provider.getNetwork();
  console.log("using chainID:", chainId);

  const shol = await ethers.getContractAt(
    "Token",
    config[chainId].shol.address
  );
  console.log("shol token fetched:", shol.address);

  const sUSD = await ethers.getContractAt(
    "Token",
    config[chainId].sUSD.address
  );
  console.log("sUSD token fetched:", sUSD.address);

  const sETH = await ethers.getContractAt(
    "Token",
    config[chainId].sETH.address
  );
  console.log("sETH token fetched:", sETH.address);

  // fetch deployed exchange
  const exchange = await ethers.getContractAt(
    "Exchange",
    config[chainId].exchange.address
  );
  console.log(`exchange token fetched: ${exchange.address}\n`);

  // give tokens to account[1]
  const sender = accounts[0];
  const receiver = accounts[1];
  let amount = tokens(10000);

  // user1 transfers 10,000 sETH..
  let transaction, result;
  transaction = await sETH.connect(sender).transfer(receiver.address, amount);
  console.log(
    `transferred ${amount} tokens from ${sender.address} to ${receiver.address}`
  );

  // set up exchange users
  const user1 = accounts[0];
  const user2 = accounts[1];
  amount = tokens(10000);

  // user1 approves 10,000 shol tokens..
  transaction = await shol.connect(user1).approve(exchange.address, amount);
  await transaction.wait();
  console.log(`approved ${amount} tokens from ${user1.address}`);

  // user1 deposit 10,000 shol tokens
  transaction = await exchange
    .connect(user1)
    .depositToken(shol.address, amount);
  await transaction.wait();
  console.log(`deposited ${amount} shol from ${user1.address}/n`);

  // user2 approves sETH
  transaction = await sETH.connect(user2).approve(exchange.address, amount);
  await transaction.wait();
  console.log(`approved ${amount} sETH tokens from ${user2.address}`);

  // user2 deposit sETH
  transaction = await exchange
    .connect(user2)
    .depositToken(sETH.address, amount);
  await transaction.wait();
  console.log(`deposited ${amount} sETH from ${user2.address}`);

  //_ seed a cancelled order

  // user1 makes order to get tokens
  let orderId;
  transaction = await exchange
    .connect(user1)
    .makeOrder(sETH.address, tokens(100), shol.address, tokens(5));
  result = await transaction.wait();
  console.log(`made order from ${user1.address}`);

  // user1 cancels order
  // console.log(result);
  orderId = result.events[0].args.id;
  transaction = await exchange.connect(user1).cancelOrder(orderId);
  result = await transaction.wait();
  console.log(`cancelled order number ${orderId} from ${user1.address}\n`);

  // wait for 1 second
  await wait(1);

  // _ seed filled orders

  // user1 make first order
  transaction = await exchange
    .connect(user1)
    .makeOrder(sETH.address, tokens(100), shol.address, tokens(5));
  result = await transaction.wait();
  console.log(`made order from ${user1.address}\n`);

  // user2 filled first order
  orderId = result.events[0].args.id;
  transaction = await exchange.connect(user2).fillOrder(orderId);
  result = await transaction.wait();
  console.log(`filled order from ${user2.address}\n`);

  // wait 1 second
  await wait(1);

  // user1 make second order
  transaction = await exchange
    .connect(user1)
    .makeOrder(sETH.address, tokens(50), shol.address, tokens(15));
  result = await transaction.wait();
  console.log(`made order from ${user1.address}\n`);

  // user2 filled second order
  orderId = result.events[0].args.id;
  transaction = await exchange.connect(user2).fillOrder(orderId);
  result = await transaction.wait();
  console.log(`filled order ${orderId} from ${user1.address}\n`);

  // wait 1 second
  await wait(1);

  // user1 make third order
  transaction = await exchange
    .connect(user1)
    .makeOrder(sETH.address, tokens(200), shol.address, tokens(20));
  result = await transaction.wait();
  console.log(`made order from ${user1.address}\n`);

  // user2 filled third order
  orderId = result.events[0].args.id;
  transaction = await exchange.connect(user2).fillOrder(orderId);
  result = await transaction.wait();
  console.log(`filled order number ${orderId} from ${user1.address}\n`);

  // wait 1 second
  await wait(1);

  // _ seed open orders

  // user1 make 10 orders
  for (let i = 1; i <= 10; i++) {
    transaction = await exchange
      .connect(user1)
      .makeOrder(sETH.address, tokens(10 * i), shol.address, tokens(10));
    result = await transaction.wait();
    console.log(`made order ${i} from ${user1.address}`);

    // wait 1 second
    await wait(1);
  }

  // user2 make 10 orders
  for (let i = 1; i <= 10; i++) {
    transaction = await exchange
      .connect(user2)
      .makeOrder(shol.address, tokens(10), sETH.address, tokens(10 * i));
    result = await transaction.wait();
    console.log(`made order ${i} from ${user2.address}`);

    // wait 1 second
    await wait(1);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
