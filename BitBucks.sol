// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract BitBucks is ChainlinkClient, ERC20 {
    using SafeERC20 for ERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    address public btcDepositAddress;  // BTC deposit address
    uint256 public constant VESTING_PERIOD = 1156 days;  // Vesting period for user tokens
    uint256 private oraclePayment = 0.1 * 10**18;  // Payment for Chainlink oracle (adjust LINK payment)
    bytes32 public currentRequestId;
    EnumerableSet.Bytes32Set private trxHashes;  // Track trxhash to prevent reuse

    struct Vesting {
        uint256 totalAmount;
        uint256 startTime;
        uint256 claimedAmount;
    }

    mapping(address => Vesting) public userVesting;  // Vesting schedule for users
    mapping(address => Vesting) public teamVesting;  // Vesting schedule for team tokens
    mapping(bytes32 => address) public requestToUser; // Mapping requestId to user

    // Team vesting parameters
    uint256 public liquidityTokens = 1944 * 10**18;  // 1,944 tokens per month for liquidity
    uint256 public legalTokens = 556 * 10**18;       // 556 tokens quarterly for legal work
    uint256 public developmentTokens = 833 * 10**18; // 833 tokens per month for development
    uint256 public treasuryTokens = 278 * 10**18;    // 278 tokens every 6 months for treasury
    uint256 public stakingTokens = 1944 * 10**18;    // 1,944 tokens per month for staking fund

    event RequestBTCValidation(bytes32 indexed requestId, bool validated, uint256 btcAmount);
    event TeamTokensVested(address indexed teamWallet, uint256 amount, string category);

    constructor(
        address _linkToken,
        address _oracle,
        address _btcDepositAddress
    ) ERC20("BitBucks", "BUK") {
        setChainlinkToken(_linkToken);
        setChainlinkOracle(_oracle);
        btcDepositAddress = _btcDepositAddress;

        // Initialize team vesting schedules
        initializeTeamVesting();
    }

    // User deposits BTC and triggers Chainlink oracle for validation
    function depositBTC(bytes32 trxhash, uint256 btcAmount) external {
        require(!trxHashes.contains(trxhash), "Transaction hash already used");
        trxHashes.add(trxhash);

        // Initiate Chainlink request to validate BTC deposit
        Chainlink.Request memory req = buildChainlinkRequest(
            "job-spec-id", 
            address(this),
            this.fulfillBTCValidation.selector
        );
        req.addBytes32("trxhash", trxhash);
        req.add("expectedAddress", btcDepositAddress);
        req.addUint("expectedAmount", btcAmount);
        currentRequestId = sendChainlinkRequest(req, oraclePayment);
        requestToUser[currentRequestId] = msg.sender;  // Map request ID to the user
    }

    // Callback function from Chainlink Oracle for BTC validation
    function fulfillBTCValidation(bytes32 _requestId, bool _validated, uint256 btcAmount) public recordChainlinkFulfillment(_requestId) {
        require(_validated, "BTC deposit validation failed");

        address user = requestToUser[_requestId];
        uint256 bukAmount = btcAmount * 2;  // Mint twice the BTC amount in BUK tokens
        _mint(user, bukAmount);

        // Start vesting schedule for the user
        userVesting[user] = Vesting(bukAmount, block.timestamp, 0);

        emit RequestBTCValidation(_requestId, _validated, btcAmount);
    }

    // Claim vested tokens (monthly claim for user)
    function claimVestedTokens() external {
        Vesting storage vesting = userVesting[msg.sender];
        require(block.timestamp >= vesting.startTime, "Vesting not started yet");
        uint256 monthsPassed = (block.timestamp - vesting.startTime) / 30 days;
        uint256 claimable = (vesting.totalAmount * monthsPassed) / (VESTING_PERIOD / 30 days);
        uint256 toClaim = claimable - vesting.claimedAmount;

        require(toClaim > 0, "No tokens available for claim");

        vesting.claimedAmount += toClaim;
        _transfer(address(this), msg.sender, toClaim);  // Transfer vested tokens to user
    }

    // Vest team tokens for the liquidity, legal, development, treasury, and staking wallets
    function vestTeamTokens(address teamWallet, uint256 amount, string memory category) internal {
        require(teamWallet != address(0), "Invalid team wallet address");
        _mint(teamWallet, amount);
        emit TeamTokensVested(teamWallet, amount, category);
    }

    // Initialize team vesting schedule for the next vesting period
    function initializeTeamVesting() internal {
        // Liquidity Vesting (Monthly for 2 years)
        vestTeamTokens(0xLiquidityWallet, liquidityTokens, "Liquidity");
        
        // Legal Work Vesting (Quarterly for 3 years)
        vestTeamTokens(0xLegalWallet, legalTokens, "Legal");

        // Development Vesting (Monthly for 5 years)
        vestTeamTokens(0xDevelopmentWallet, developmentTokens, "Development");

        // Treasury Vesting (Every 6 months for 5 years)
        vestTeamTokens(0xTreasuryWallet, treasuryTokens, "Treasury");

        // Staking Fund Vesting (Monthly for 2 years)
        vestTeamTokens(0xStakingWallet, stakingTokens, "Staking Fund");
    }

    // Set up LINK payment for oracle job
    function setOraclePayment(uint256 _oraclePayment) external {
        oraclePayment = _oraclePayment;
    }

    // Withdraw LINK tokens from the contract (if needed)
    function withdrawLink() external {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}
