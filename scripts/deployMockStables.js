require('@nomiclabs/hardhat-ethers');
require('hardhat-deploy');
require('hardhat-deploy-ethers');
const task = require('hardhat/config').task;

task('deploy-stables', 'Deploy Stables')
  .setAction(async (args , hre) => {
    const { deployments, ethers, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const usdc = await deploy('USDC', {
      from: deployer,
      args: [],
      log: true,
    });
    console.log(`USDC deployed at ${usdc.address}`);

    const usdt = await deploy('USDT', {
      from: deployer,
      args: [],
      log: true,
    });
    console.log(`USDT deployed at ${usdt.address}`);

    console.log('Minting stables');
    const usdcAddress = (await deployments.get('USDC')).address;
    const usdtAddress = (await deployments.get('USDT')).address;
    const usdcContract = await ethers.getContractAt('USDC', usdcAddress);
    await usdcContract.mint(ethers.BigNumber.from('1000000000000000000000000'));
    const usdtContract = await ethers.getContractAt('USDT', usdtAddress);
    await usdtContract.mint(ethers.BigNumber.from('1000000000000000000000000'));

    // await Utils.verify(run, waifuDeploy.address);
  });
