const hardhat = require('hardhat');

describe('DTECToken', () => {
  let dtecCF;
  let dtec;
  let bob;
  let alice;

  before(async () => {
    dtecCF = await hardhat.ethers.getContractFactory('DTEC');
    const signers = await hardhat.ethers.getSigners();
    bob = signers[0];
    alice = signers[1];
  });

  beforeEach(async () => {
    dtec = await dtecCF.connect(bob).deploy();
  });

  describe('Dtec Token Tests', () => {
    it('Minted Supply', async () => {
      const balance = await dtec.balanceOf(bob.address);
      const numBalance = parseFloat(hardhat.ethers.utils.formatEther(balance));
      if (numBalance !== 900000000) {
        throw new Error('Wrong supply');
      }
    });

    it('Transfer', async () => {
      await dtec.connect(bob).transfer(alice.address, hardhat.ethers.utils.parseEther('100'));
      const aliceBalance = await dtec.connect(alice).balanceOf(alice.address);
      const numBalance = parseFloat(hardhat.ethers.utils.formatEther(aliceBalance));
      if (numBalance !== 100) {
        throw new Error('Wrong alice balance');
      }
    });

    it('Burn', async () => {
      await dtec.connect(bob).burn(hardhat.ethers.utils.parseEther('100'));
    });
  });
});
