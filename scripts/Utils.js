class Utils {
  static async verify(run, address, constructorArguments) {
    if (!constructorArguments) {
      constructorArguments = [];
    }
    try {
      await run('verify:verify', {
        address: address,
        constructorArguments: constructorArguments,
      });
    } catch (err) {
      console.error(err)
    }
  }
}

module.exports = Utils;
