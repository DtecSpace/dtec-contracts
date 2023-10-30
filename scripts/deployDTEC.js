require('@nomiclabs/hardhat-ethers');
require('hardhat-deploy');
require('hardhat-deploy-ethers');
const Utils = require('./Utils');
const task = require('hardhat/config').task;

task('deploy-dtec', 'Deploy DTEC')
  .setAction(async (args , hre) => {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const dtecDeploy = await deploy('DTEC', {
      from: deployer,
      args: [],
      log: true,
    });
    console.log(`DTEC deployed at ${dtecDeploy.address}`);

    const dtecAddress = (await deployments.get('DTEC')).address;
    await Utils.verify(run, dtecAddress);
  });
