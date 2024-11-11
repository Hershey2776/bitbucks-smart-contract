// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TestBucks11 is ERC20, Pausable {
    using SafeERC20 for IERC20;

    AggregatorV3Interface public priceFeed;
    address public admin;
    IERC20 public usdt;
    // Minimum deposit amount for USDT
    uint256 public minDepositAmount;
    // Timestamp for the last time the minimum deposit amount was updated
    uint256 public lastUpdateTimestamp;


    // Constants for vesting periods in seconds (for testing)
    uint256 private constant TOTAL_SECONDS = 1156; // Total vesting period in seconds
    uint256 private constant VESTING_INTERVAL_SECONDS = 34; // Vesting interval in seconds
    uint256 private constant RELEASE_PERIODS = TOTAL_SECONDS / VESTING_INTERVAL_SECONDS;

    // Maximum supply for the token
    uint256 private constant MAX_SUPPLY = 21_000_000 * (10 ** 18); // 21 million tokens with 18 decimals

    struct VestingSchedule {
        uint256 totalAmount;
        uint256 amountClaimed;
        uint256 startTime;
    }

    struct TeamVestingSchedule {
        uint256 totalAmount;
        uint256 amountClaimed;
        uint256 releaseInterval;
        uint256 startTime;
        uint256 duration;
    }

    mapping(address => VestingSchedule[]) public vestingSchedules;
    mapping(address => TeamVestingSchedule[]) public teamVestingSchedules;

    // Events
    event BuksIssued(address indexed user, uint256 usdtAmount, uint256 btcAmount, uint256 bukAmount);
    event TokensClaimed(address indexed user, uint256 amount);
    event ReferralBonus(address indexed referrer, uint256 bonusAmount);
        event PriceFeedUpdated(address indexed oldPriceFeed, address indexed newPriceFeed);

    // Hardcoded wallet addresses for team vesting
    address public constant LIQUIDITY_WALLET = 0x90f727dDd8798c7c5711ef6eab9E539acd1c8f3b; // Replace with actual wallet
    address public constant LEGAL_WALLET = 0x0C6df3cc2e67e2522c14E025fa22Db301C6689F9; // Replace with actual wallet
    address public constant DEVELOPMENT_WALLET = 0x0C6df3cc2e67e2522c14E025fa22Db301C6689F9; // Replace with actual wallet
    address public constant TREASURY_WALLET = 0x0C6df3cc2e67e2522c14E025fa22Db301C6689F9; // Replace with actual wallet
    address public constant STAKING_WALLET = 0x0C6df3cc2e67e2522c14E025fa22Db301C6689F9; // Replace with actual wallet


    constructor(address _priceFeed, address _admin, address _usdt, uint256 _minDepositAmount) ERC20("BUKs", "BUKs") {
        require(_admin != address(0), "Invalid admin address");
        require(_priceFeed != address(0), "Invalid price feed address");
        require(_usdt != address(0), "Invalid USDT address");

        priceFeed = AggregatorV3Interface(_priceFeed);
        admin = _admin;
        usdt = IERC20(_usdt);
        minDepositAmount = _minDepositAmount; // Set minimum deposit amount

        _initializeTeamVesting();


teamVestingSchedules[LIQUIDITY_WALLET].push(TeamVestingSchedule(30.5 * (10 ** 18), 0, 30, block.timestamp, 4 * 365 * 24 * 60 * 60)); // Liquidity
teamVestingSchedules[LEGAL_WALLET].push(TeamVestingSchedule(27.8 * (10 ** 18), 0, 90, block.timestamp, 4 * 365 * 24 * 60 * 60)); // Legal
teamVestingSchedules[DEVELOPMENT_WALLET].push(TeamVestingSchedule(17.3 * (10 ** 18), 0, 30, block.timestamp, 4 * 365 * 24 * 60 * 60)); // Development
teamVestingSchedules[TREASURY_WALLET].push(TeamVestingSchedule(5.7 * (10 ** 18), 0, 180, block.timestamp, 4 * 365 * 24 * 60 * 60)); // Treasury
teamVestingSchedules[STAKING_WALLET].push(TeamVestingSchedule(43.33 * (10 ** 18), 0, 30, block.timestamp, 5 * 365 * 24 * 60 * 60)); // Staking
    }




    function _initializeTeamVesting() internal {
        // Liquidity vesting: 30.5 tokens per month for 4 years
        teamVestingSchedules[LIQUIDITY_WALLET].push(TeamVestingSchedule({
            totalAmount: 30.5 * 12 * 4 * (10 ** 18),
            amountClaimed: 0,
            releaseInterval: 30 seconds,
            startTime: block.timestamp,
            duration: 4 * 365 seconds
        }));

        // Legal vesting: 27.8 tokens quarterly for 4 years
        teamVestingSchedules[LEGAL_WALLET].push(TeamVestingSchedule({
            totalAmount: 27.8 * 4 * 4 * (10 ** 18),
            amountClaimed: 0,
            releaseInterval: 90 seconds,
            startTime: block.timestamp,
            duration: 4 * 365 seconds
        }));

        // Development vesting: 17.3 tokens per month for 4 years
        teamVestingSchedules[DEVELOPMENT_WALLET].push(TeamVestingSchedule({
            totalAmount: 17.3 * 12 * 4 * (10 ** 18),
            amountClaimed: 0,
            releaseInterval: 30 seconds,
            startTime: block.timestamp,
            duration: 4 * 365 seconds
        }));

        // Treasury vesting: 5.7 tokens every 6 months for 4 years
        teamVestingSchedules[TREASURY_WALLET].push(TeamVestingSchedule({
            totalAmount: 5.7 * 2 * 4 * (10 ** 18),
            amountClaimed: 0,
            releaseInterval: 180 seconds,
            startTime: block.timestamp,
            duration: 4 * 365 seconds
        }));

        // Staking vesting: 43.33 tokens per month for 5 years
        teamVestingSchedules[STAKING_WALLET].push(TeamVestingSchedule({
            totalAmount: 43.33 * 12 * 5 * (10 ** 1),
            amountClaimed: 0,
            releaseInterval: 30 days,
            startTime: block.timestamp,
            duration: 5 * 365 days
        }));
    }

        // Function to allow admin to update the price feed address
    function updatePriceFeed(address _newPriceFeed) external onlyAdmin {
        require(_newPriceFeed != address(0), "Invalid price feed address");
        address oldPriceFeed = address(priceFeed);
        priceFeed = AggregatorV3Interface(_newPriceFeed);

        emit PriceFeedUpdated(oldPriceFeed, _newPriceFeed);
    }

    function getBitcoinPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
    function setMinDepositAmount(uint256 _minDepositAmount) external onlyAdmin {
        // Allow admin to set a new minimum deposit amount only every 4 months
        require(block.timestamp >= lastUpdateTimestamp + 4 * 30 days, "Can only update every 4 months");
        minDepositAmount = _minDepositAmount;
        lastUpdateTimestamp = block.timestamp;
    }


 function depositUSDT(uint256 _usdtAmount, address referrer) external whenNotPaused {
    require(_usdtAmount >= minDepositAmount, "Amount below minimum deposit");
        usdt.safeTransferFrom(msg.sender, address(this), _usdtAmount);

    // Prevent self-referral
    require(referrer != msg.sender, "Cannot refer yourself");

    // Get BTC price in USD (8 decimals)
    int256 btcPriceInUSD = getBitcoinPrice();
    require(btcPriceInUSD > 0, "Invalid BTC price");

    // Convert _usdtAmount to 18 decimals (from 6 decimals)
    uint256 usdtAmountIn18Decimals = _usdtAmount * 10**12;

    // Calculate BTC amount in 18 decimals to match BUK's standard (8 for BTC price, 10 more for decimal alignment)
    uint256 btcAmount = (usdtAmountIn18Decimals * 10**8) / uint256(btcPriceInUSD);

    // Calculate BUK amount in 18 decimals
    uint256 bukAmount = btcAmount * 2; 

    // Check if minting would exceed max supply
    require(totalSupply() + bukAmount <= MAX_SUPPLY, "Max supply exceeded");

    // Create vesting schedule
    VestingSchedule memory schedule = VestingSchedule({
        totalAmount: bukAmount,
        amountClaimed: 0,
        startTime: block.timestamp
    });
    vestingSchedules[msg.sender].push(schedule);

    emit BuksIssued(msg.sender, _usdtAmount, btcAmount, bukAmount);

    // Issue 5% referral bonus to the referrer if provided
    if (referrer != address(0)) {
        uint256 bonusAmount = (bukAmount * 5) / 100;
        vestingSchedules[referrer].push(VestingSchedule({
            totalAmount: bonusAmount,
            amountClaimed: 0,
            startTime: block.timestamp
        }));
        emit ReferralBonus(referrer, bonusAmount);
    }
}
    function calculateVestedAmount(VestingSchedule memory schedule) internal view returns (uint256) {
        uint256 elapsedTime = block.timestamp - schedule.startTime;
        uint256 periodsElapsed = elapsedTime / VESTING_INTERVAL_SECONDS;

        if (periodsElapsed > RELEASE_PERIODS) {
            periodsElapsed = RELEASE_PERIODS;
        }

        return (schedule.totalAmount * periodsElapsed) / RELEASE_PERIODS;
    }

function claimTokens() external whenNotPaused {
    uint256 totalClaimable = 0;
    uint256 maxAvailableToMint = MAX_SUPPLY - totalSupply();

    for (uint256 i = 0; i < vestingSchedules[msg.sender].length; i++) {
        VestingSchedule storage schedule = vestingSchedules[msg.sender][i];
        uint256 vested = calculateVestedAmount(schedule);
        uint256 claimable = vested - schedule.amountClaimed;

        if (claimable > 0) {
            // Adjust claimable to max available if it exceeds remaining mintable supply
            if (totalClaimable + claimable > maxAvailableToMint) {
                claimable = maxAvailableToMint - totalClaimable;
            }

            schedule.amountClaimed += claimable;
            totalClaimable += claimable;

            // If the maximum mintable tokens have been reached, exit the loop
            if (totalClaimable == maxAvailableToMint) {
                break;
            }
        }
    }

    require(totalClaimable > 0, "No tokens available for claim");

    _mint(msg.sender, totalClaimable);
    emit TokensClaimed(msg.sender, totalClaimable);
}


   function claimTeamTokens() external whenNotPaused {
    // Check if the caller's address is one of the team wallets
    require(
        msg.sender == LIQUIDITY_WALLET ||
        msg.sender == LEGAL_WALLET ||
        msg.sender == DEVELOPMENT_WALLET ||
        msg.sender == TREASURY_WALLET ||
        msg.sender == STAKING_WALLET,
        "Unauthorized: Not a team wallet"
    );

    TeamVestingSchedule[] storage schedules = teamVestingSchedules[msg.sender];
    require(schedules.length > 0, "No team vesting schedule");

    uint256 totalClaimable = 0;

    for (uint256 i = 0; i < schedules.length; i++) {
        TeamVestingSchedule storage schedule = schedules[i];

        uint256 elapsedTime = block.timestamp - schedule.startTime;
        if (elapsedTime >= schedule.duration) {
            uint256 remainingAmount = schedule.totalAmount - schedule.amountClaimed;
            schedule.amountClaimed = schedule.totalAmount;
            totalClaimable += remainingAmount;
        } else {
            uint256 periodsElapsed = elapsedTime / schedule.releaseInterval;
            uint256 vestedAmount = (schedule.totalAmount * periodsElapsed) / (schedule.duration / schedule.releaseInterval);
            uint256 claimableAmount = vestedAmount - schedule.amountClaimed;
            schedule.amountClaimed += claimableAmount;
            totalClaimable += claimableAmount;
        }
    }

    require(totalClaimable > 0, "No tokens available for claim");
    _mint(msg.sender, totalClaimable);
    emit TokensClaimed(msg.sender, totalClaimable);
}

    
   function withdrawUSDT(uint256 _amount) external onlyAdmin {
        require(_amount > 0, "Amount must be greater than 0");
        require(usdt.balanceOf(address(this)) >= _amount, "Insufficient USDT balance");

        // Use safeTransfer instead of transfer
        usdt.safeTransfer(admin, _amount);
    }


    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
}
