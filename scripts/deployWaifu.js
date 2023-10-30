require('@nomiclabs/hardhat-ethers');
require('hardhat-deploy');
require('hardhat-deploy-ethers');
const task = require('hardhat/config').task;
const Utils = require('./Utils');

task('deploy-waifu', 'Deploy Waifu')
  .setAction(async (args , hre) => {
    const { deployments, ethers, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const revealAddress = (await deployments.get('WaifuReveal')).address;
    const waifuDeploy = await deploy('Waifu2', {
      from: deployer,
      args: [],
      log: true,
    });
    console.log(`Waifu2 deployed at ${waifuDeploy.address}`);

    const waifu2 = await ethers.getContractAt('Waifu2', waifuDeploy.address);
    let tx = await waifu2.setRevealAddress(revealAddress);
    await tx.wait();
    // TODO:::
    tx = await waifu2.setUnrevealedURI('ipfs://bafybeickndcaqwmekqhh6fi45smzls7fnvlzwykyljvdvxrbes4ee77mt4/299.json');
    await tx.wait();
    tx = await waifu2.setRoyalty('0x7E3fdFD16e42582bC134442670F2462B4Fd1d37F', 690);
    await tx.wait();
    tx = await waifu2.setBaseURI('ipfs://bafybeickndcaqwmekqhh6fi45smzls7fnvlzwykyljvdvxrbes4ee77mt4/');
    await tx.wait();

    await Utils.verify(run, waifuDeploy.address);
  });
