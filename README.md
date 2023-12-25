# DTEC Token Ecosystem

## Overview

This repository hosts the smart contracts for the DTEC token ecosystem, deployed on the Polygon network. It features a comprehensive suite of contracts for the DTEC ERC20 token, along with mechanisms for token sales, vesting, and locking to manage the token's lifecycle from inception to distribution.

## Contracts

### DTEC Token Contract

- **DTEC.sol**: The ERC20 token contract for DTEC with a capped supply and burn function.
  - **Max Supply**: 900 million DTEC tokens.
  - **Features**: Allows token holders to burn their tokens, thereby reducing the total circulating supply.

### Token Sale Contracts

- **DTECTokenSale.sol**: The base contract for managing the initial sale of DTEC tokens.
- **DTECPrivateSale.sol**: Manages the private sale phase with specific purchasing limits.
- **DTECPublicSale.sol**: Manages the public sale phase with individual purchase and allocation limits.
- **DTECPreSale.sol**: Manages the presale phase with tailored purchasing and allocation requirements.

### Vesting Contracts

A collection of contracts managing the vesting of DTEC tokens for various stakeholders:

- **Vesting.sol**: Base vesting contract with a linear release schedule.
- **Team.sol**: Vesting contract for team members.
- **Advisors.sol**: Vesting contract for advisors.
- **Airdrop.sol**: Vesting contract for airdrop participants.
- **Development.sol**: Vesting contract for development funds.
- **EcosystemFund.sol**: Vesting contract for the ecosystem fund.
- **FutureInvest.sol**: Vesting contract for future investments.
- **Liquidity.sol**: Vesting contract for liquidity provisioning.
- **Marketing.sol**: Vesting contract for marketing activities.
- **Partners.sol**: Vesting contract for partners.
- **Staking.sol**: Vesting contract for staking rewards.
- **DataSharingVesting.sol**: Specialized vesting contract for data sharing initiatives.

### Lock Contracts

- **LinearLock.sol**: Base contract for linear locking of tokens.
- **PreSaleLock.sol**: Locking mechanism for presale tokens.
- **PrivateSaleLock.sol**: Locking mechanism for private sale tokens.
- **PublicSaleLock.sol**: Locking mechanism for public sale tokens.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for full details.
