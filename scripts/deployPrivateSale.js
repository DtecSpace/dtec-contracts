require('@nomiclabs/hardhat-ethers');
require('hardhat-deploy');
require('hardhat-deploy-ethers');
const Utils = require('./Utils');
const task = require('hardhat/config').task;

task('deploy-private-sale', 'Deploy private sale')
  .setAction(async (args , hre) => {
    const { deployments, ethers, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const testReceiver = '0xDCbA1401ce2f323e5e1A11f35A7787323e078b64';
    // const usdcAddress = (await deployments.get('USDC')).address;
    // const usdtAddress = (await deployments.get('USDT')).address;
    const dtecAddress = (await deployments.get('DTEC')).address;

    const lockDeploy = await deploy('PrivateSaleLock', {
      from: deployer,
      args: [
        dtecAddress,
      ],
      log: true,
    });
    console.log(`PrivateSaleLock deployed at ${lockDeploy.address}`);

    const priSaleDeploy = await deploy('DTECPrivateSale', {
      from: deployer,
      args: [
        testReceiver,
        dtecAddress,
        lockDeploy.address,
      ],
      log: true,
    });
    console.log(`DTECPrivateSale deployed at ${priSaleDeploy.address}`);

    // console.log('Altering stables');
    // const priSale = await ethers.getContractAt('DTECPrivateSale', priSaleDeploy.address);
    // await priSale.setStableAddresses(usdcAddress, usdtAddress);

    console.log('Configuring locker');
    const priSaleLock = await ethers.getContractAt('PrivateSaleLock', lockDeploy.address);
    await priSaleLock.setTokenLocker(priSaleDeploy.address);

    await Utils.verify(run, lockDeploy.address);
    await Utils.verify(run, priSaleDeploy.address);
  });
