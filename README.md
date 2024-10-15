BitBucks Smart Contract

This repository contains the smart contract for BitBucks, a decentralized token system built on the BSC20 chain. The contract handles BTC deposits, validates transactions using Chainlink oracles, mints tokens at a 2x rate based on the deposited BTC, and manages a vesting schedule for the minted tokens. The contract is designed to be fully decentralized with no admin control.
Key Features
1. BTC Deposit Verification

    Users deposit BTC to a predefined address.
    They provide the transaction hash (trxhash) of the BTC transaction to the smart contract.
    The smart contract uses a Chainlink oracle to validate the transaction and confirm the deposit.

2. Chainlink Oracle Integration

    The contract integrates with a Chainlink oracle to validate BTC deposits.
    Once the oracle confirms the deposit, the contract mints twice the value of the deposited BTC in BitBucks tokens.
    Oracle confirmation is required to ensure that deposits are valid and only credited once.

3. Token Minting and Vesting

    Upon confirmation, the contract mints tokens at a 2:1 ratio (2 tokens for every 1 BTC deposited).
    The minted tokens are subject to a vesting schedule over 1156 days.
    Users can claim their vested tokens monthly during this period.

4. Team Token Vesting

    The contract includes pre-defined vesting schedules for the team:
        Liquidity: 1,944 tokens vested monthly for 2 years.
        Legal Work: 556 tokens vested quarterly for 3 years.
        Development: 833 tokens vested monthly for 5 years.
        Treasury: 278 tokens vested every 6 months for 5 years.
        Staking Fund: 1,944 tokens vested monthly for 2 years.

5. Decentralized Architecture

    The contract is designed to be fully decentralized with no admin or owner control.
    There are no backdoors or administrative privileges, ensuring the contract operates autonomously.

6. Security and Transparency

    Transaction hashes are stored on-chain to prevent double-spending or reusing a transaction for multiple deposits.
    The contract ensures that only deposits made to the specified BTC address are valid.
    Chainlink oracles provide an additional layer of security and transparency by verifying off-chain data.

Contract Structure
Main Contract: BitBucks.sol

This contract manages the core functionality of the BitBucks token system.
Key Functions:

    depositBTC(trxhash): Allows users to submit a BTC transaction hash for validation.
    requestBTCValidation(trxhash): Initiates a Chainlink oracle request to validate the BTC transaction.
    fulfillBTCValidation(trxhash, valid): Callback function from the Chainlink oracle that mints tokens upon successful validation.
    claimVestedTokens(): Allows users to claim their vested tokens every month.
    recordedTrxhashes: Mapping to store and prevent reuse of BTC transaction hashes.

Chainlink Oracle Integration

    The contract utilizes Chainlink’s oracle network to validate BTC transactions.
    Once a BTC deposit is made and the transaction hash is provided, the Chainlink node calls an API to verify the transaction.
    Upon successful verification, the contract mints BitBucks tokens.
