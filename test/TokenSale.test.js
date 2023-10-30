const hardhat = require('hardhat');

describe('DTECToken', () => {
  let dtecCF;
  let mockLock;
  let usdc;
  let usdt;
  let dtec;
  let deployer;
  let bob;
  let alice;

  before(async () => {
    dtecCF = await hardhat.ethers.getContractFactory('DTEC');
    const usdcCF = await hardhat.ethers.getContractFactory('USDC');
    usdc = await usdcCF.deploy();
    const usdtCF = await hardhat.ethers.getContractFactory('USDT');
    usdt = await usdtCF.deploy();
    const lockCF = await hardhat.ethers.getContractFactory('MockLock');
    mockLock = await lockCF.deploy();

    const signers = await hardhat.ethers.getSigners();
    deployer = signers[0]
    bob = signers[1];
    alice = signers[2];
  });

  beforeEach(async () => {
    dtec = await dtecCF.connect(deployer).deploy();
    await usdc.connect(bob).mint(hardhat.ethers.utils.parseEther('10000'));
    await usdt.connect(bob).mint(hardhat.ethers.utils.parseEther('10000'));
    await usdc.connect(alice).mint(hardhat.ethers.utils.parseEther('10000'));
    await usdt.connect(alice).mint(hardhat.ethers.utils.parseEther('10000'));
  });

  const deploySaleContract = async (type) => {
    const cf = await hardhat.ethers.getContractFactory(type);
    const contract = await cf.deploy(deployer.address, dtec.address, mockLock.address);
    await contract.togglePause();
    await contract.setStableAddresses(usdc.address, usdt.address);
    await dtec.connect(deployer).transfer(contract.address, hardhat.ethers.utils.parseEther('1000000'));
    return contract;
  };

  describe('Token Sale Tests', () => {
    it('Private Sale (USDT)', async () => {
      const privateSale = await deploySaleContract('DTECPrivateSale');
      await privateSale.addWLs([bob.address, alice.address]);
      const cost = await privateSale.getBuyCost(72000);
      await usdt.connect(bob).approve(privateSale.address, cost);
      await privateSale.connect(bob).buyTokens(72000, false);

      const balance = parseFloat(hardhat.ethers.utils.formatEther(await dtec.balanceOf(bob.address)));
      const lockBalance = parseFloat(hardhat.ethers.utils.formatEther(await dtec.balanceOf(mockLock.address)));
      if (balance !== 1440 || lockBalance !== 70560) {
        throw new Error('Invalid calculation');
      }
    });

    it('Private Sale (USDC)', async () => {
      const privateSale = await deploySaleContract('DTECPrivateSale');
      await privateSale.addWLs([bob.address]);
      const cost = await privateSale.getBuyCost(72000);
      await usdc.connect(bob).approve(privateSale.address, cost);
      await privateSale.connect(bob).buyTokens(72000, true);
      const balance = parseFloat(hardhat.ethers.utils.formatEther(await dtec.balanceOf(bob.address)));
      if (balance !== 1440) {
        throw new Error('Invalid calculation');
      }
    });

    it('Pre Sale (USDT)', async () => {
      const preSale = await deploySaleContract('DTECPreSale');
      const cost = await preSale.getBuyCost(72000);
      await usdt.connect(bob).approve(preSale.address, cost);
      await preSale.connect(bob).buyTokens(72000, false);
      const balance = parseFloat(hardhat.ethers.utils.formatEther(await dtec.balanceOf(bob.address)));
      const lockBalance = parseFloat(hardhat.ethers.utils.formatEther(await dtec.balanceOf(mockLock.address)));
      if (balance !== 4320 || lockBalance !== 67680) {
        throw new Error('Invalid calculation');
      }
    });

    it('Public Sale (USDT)', async () => {
      const publicSale = await deploySaleContract('DTECPublicSale');
      const cost = await publicSale.getBuyCost(72000);
      await usdt.connect(bob).approve(publicSale.address, cost);
      await publicSale.connect(bob).buyTokens(72000, false);
      const balance = parseFloat(hardhat.ethers.utils.formatEther(await dtec.balanceOf(bob.address)));
      const lockBalance = parseFloat(hardhat.ethers.utils.formatEther(await dtec.balanceOf(mockLock.address)));
      if (balance !== 7200 || lockBalance !== 64800) {
        throw new Error('Invalid calculation');
      }
    });
  });
});
