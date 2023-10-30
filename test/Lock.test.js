const hardhat = require('hardhat');
const { time } = require('@nomicfoundation/hardhat-network-helpers');

describe('Lock', () => {
  let dtecCF;
  let linearLockCF;
  let publicSaleLockCF;
  let dtec;
  let linearLock;
  let publicSaleLock;
  let deployer;
  let bob;
  let alice;

  before(async () => {
    dtecCF = await hardhat.ethers.getContractFactory('DTEC');
    linearLockCF = await hardhat.ethers.getContractFactory('LinearLock');
    publicSaleLockCF = await hardhat.ethers.getContractFactory('PublicSaleLock');
    const signers = await hardhat.ethers.getSigners();
    deployer = signers[0];
    bob = signers[1];
    alice = signers[2];
  });

  beforeEach(async () => {
    dtec = await dtecCF.connect(deployer).deploy();
    linearLock = await linearLockCF.deploy(dtec.address);
    await linearLock.setTokenLocker(deployer.address);
    publicSaleLock = await publicSaleLockCF.deploy(dtec.address, deployer.address);
  });

  describe('Lock Tests', () => {
    it('Lock tokens', async () => {
      await dtec.connect(deployer).transfer(linearLock.address, 1000);
      await linearLock.connect(deployer).lockTokens(bob.address, 1000);
      await dtec.connect(deployer).transfer(publicSaleLock.address, 1000);
      await publicSaleLock.connect(deployer).lockTokens(bob.address, 1000);
    });

    it('Period test (Linear Lock)', async () => {
      await dtec.connect(deployer).transfer(linearLock.address, 1000);
      const startTs = await time.latest();
      await linearLock.setReleaseInfo(startTs, 2000);
      await linearLock.lockTokens(bob.address, 1000);
      await linearLock.setPeriod(1); // Set clock
      await linearLock.connect(bob).claim();
      const balance = await dtec.balanceOf(bob.address);
      const claimTs = await time.latest();
      const shouldClaim = 1000 * ((claimTs - startTs) * 20) / 100;
      if (balance.toNumber() !== shouldClaim) {
        throw new Error(`Lock failure, Expected:${shouldClaim}, Got:${balance}`);
      }
      await linearLock.setPeriod(1); // Set clock
      await linearLock.setPeriod(1); // Set clock
      const newShouldClaim = 1000 - shouldClaim;
      const claimable = await linearLock.getClaimable(bob.address);
      if (claimable.toNumber() !== newShouldClaim) {
        throw new Error(`Lock failure2, Expected:${shouldClaim}, Got:${balance}`);
      }
      await linearLock.connect(bob).claim();
      await linearLock.setPeriod(1); // Set clock
      await linearLock.setPeriod(1); // Set clock
      const claimableFinal = await linearLock.getClaimable(bob.address);
      if (claimableFinal.toNumber() !== 0) {
        throw new Error('Shiiit');
      }
    });

    it('Period test (Linear Lock)', async () => {
      await dtec.connect(deployer).transfer(publicSaleLock.address, 1000);
      const startTs = await time.latest();
      await publicSaleLock.setReleaseInfo(startTs);
      await publicSaleLock.setPeriod(2);
      await publicSaleLock.lockTokens(bob.address, 1000);
      await publicSaleLock.setPeriod(2); // set clock
      await publicSaleLock.connect(bob).claim();
      const balance = await dtec.balanceOf(bob.address);
      const claimTs = await time.latest();
      const diff = claimTs - startTs;

      let expected;
      if (diff === 0) {
        expected = 0;
      } else if (diff < 4) {
        expected = 200;
      } else if (diff < 8) {
        expected = 500;
      } else if (diff > 2) {

      }


      // const balance = await dtec.balanceOf(bob.address);
      // const claimTs = await time.latest();
      // console.log(balance.toNumber());
      // const shouldClaim = 1000 * ((claimTs - startTs) * 20) / 100;
      // if (balance.toNumber() !== shouldClaim) {
      //   throw new Error(`Lock failure, Expected:${shouldClaim}, Got:${balance}`);
      // }
    });
  });
});
