// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Interface for the option contract with an execution hook
interface IOption {
    function executeOption() external;
}

// Minimal ERC20 interface for NECT token interactions
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

// Enum to differentiate between call and put options
enum OptionType {
    CALL,
    PUT
}

// Main allocator contract for writing options using LSP capital
contract LSPAllocator {

    address public owner; // Deployer/admin
    address public lsp; // Address of the Liquid Stability Pool
    address public optionImplementation; // Template or factory for option contract
    address public pythAssetId; // Hardcoded as SPX in current setup
    address public paymentToken; // Token used for payment and collateral, i.e. NECT
    uint256 public bufferRatio = 30; // % of capital reserved for offset() needs
    uint256 public lspPremiumShare = 80; // % of premiums routed back to LSP
    uint256 public treasuryPremiumShare = 20; // % of premiums routed to treasury
    address public treasury; // Address for treasury to receive its share

    // Struct tracking deployed option contracts
    struct OptionPosition {
        address contractAddress;
        uint256 amount;
        uint256 expiry;
        bool settled;
    }

    OptionPosition[] public activeOptions;

    uint256 public totalAllocated; // Total funds provided by LSP
    uint256 public usedForOptions; // Funds locked in active options
    uint256 public totalPremiumsCollected; // Premiums earned from users

    constructor(address _lsp, address _optionImplementation, address _paymentToken) {
        owner = msg.sender;
        lsp = _lsp;
        optionImplementation = _optionImplementation;
        paymentToken = _paymentToken;
        treasury = msg.sender; // Default treasury to deployer
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not allowed");
        _;
    }

    // Called by LSP to deposit funds into the allocator
    function allocate(uint256 amount) external {
        require(msg.sender == lsp, "Only LSP can allocate");
        IERC20(paymentToken).transferFrom(msg.sender, address(this), amount);
        totalAllocated += amount;
    }

    // View function for the amount of capital still liquid and available for offset
    function availableForOffset() external view returns (uint256) {
        return totalAllocated * bufferRatio / 100;
    }

    // Buyer-facing function to write a new option contract
    function writeOption(
        uint strikePrice,
        uint expiration,
        uint executionWindow,
        uint premium,
        uint amount,
        uint8 optionType
    ) public {
        require(amount <= totalAllocated * (100 - bufferRatio) / 100, "Insufficient buffer");

        // Buyer pays premium to contract
        IERC20(paymentToken).transferFrom(msg.sender, address(this), premium);
        totalPremiumsCollected += premium;

        // Deploy and configure the new option
        address newOption = deployOption(
            OptionType(optionType),
            strikePrice,
            expiration,
            executionWindow,
            premium,
            amount
        );

        activeOptions.push(OptionPosition({
            contractAddress: newOption,
            amount: amount,
            expiry: expiration,
            settled: false
        }));

        usedForOptions += amount;
        totalAllocated -= amount;
    }

    // Internal helper to create new option contracts
    function deployOption(
        OptionType optionType,
        uint strike,
        uint expiry,
        uint executionWindow,
        uint premium,
        uint amount
    ) internal returns (address) {
        // Option is deployed (not using factory pattern for simplicity)
        Option newOption = new Option(
            optionType,
            "SPX.PYTH",
            strike,
            expiry,
            executionWindow,
            premium,
            amount,
            paymentToken
        );

        // Allocator becomes owner of the deployed option
        newOption.transferOwnership(address(this));

        // Approve the full option size to the contract
        IERC20(paymentToken).approve(address(newOption), amount);
        return address(newOption);
    }

    // Placeholder for potential collateral substitution when offset() is triggered
    function backstopWithCollateral(uint256 nectNeeded, address collateralToken, uint256 value) external {
        require(msg.sender == lsp, "Only LSP");
        // Future implementation goes here
    }

    // Settle an option after expiry
    function settleOption(uint index) external onlyOwner {
        OptionPosition storage pos = activeOptions[index];
        require(block.timestamp > pos.expiry, "Not expired");
        require(!pos.settled, "Already settled");

        IOption(pos.contractAddress).executeOption();
        pos.settled = true;
        usedForOptions -= pos.amount;
    }

    // Manually return unused capital to the LSP
    function returnToLSP(uint amount) external onlyOwner {
        require(amount <= totalAllocated, "Too much");
        totalAllocated -= amount;
        IERC20(paymentToken).transfer(lsp, amount);
    }

    // Withdraw collected premiums and return them proportionally to LSP and Treasury
    function withdrawPremiums() external onlyOwner {
        require(totalPremiumsCollected > 0, "No premiums");
        uint256 amount = totalPremiumsCollected;
        totalPremiumsCollected = 0;

        uint256 lspAmount = (amount * lspPremiumShare) / 100;
        uint256 treasuryAmount = amount - lspAmount;

        IERC20(paymentToken).transfer(lsp, lspAmount);
        IERC20(paymentToken).transfer(treasury, treasuryAmount);
    }

    // Auto-compound collected premiums by writing additional options
    function autoCompoundPremium(
        uint strikePrice,
        uint expiration,
        uint executionWindow,
        uint premium,
        uint amount,
        uint8 optionType
    ) external onlyOwner {
        require(totalPremiumsCollected >= premium, "Insufficient premiums");
        require(amount <= totalAllocated * (100 - bufferRatio) / 100, "Insufficient buffer");

        totalPremiumsCollected -= premium;

        address newOption = deployOption(
            OptionType(optionType),
            strikePrice,
            expiration,
            executionWindow,
            premium,
            amount
        );

        activeOptions.push(OptionPosition({
            contractAddress: newOption,
            amount: amount,
            expiry: expiration,
            settled: false
        }));

        usedForOptions += amount;
        totalAllocated -= amount;
    }

    // Allow updating premium share distribution
    function updatePremiumDistribution(uint256 _lspShare, uint256 _treasuryShare) external onlyOwner {
        require(_lspShare + _treasuryShare == 100, "Invalid distribution");
        lspPremiumShare = _lspShare;
        treasuryPremiumShare = _treasuryShare;
    }

    // Set new treasury address
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
    }
}

// Dummy implementation of an Option contract
// In production this would be external and fully implemented
contract Option {
    address public owner;

    constructor(
        OptionType optionType,
        string memory pythAssetId,
        uint strikePrice,
        uint expiry,
        uint executionWindow,
        uint premium,
        uint amount,
        address paymentToken
    ) {
        owner = msg.sender;
    }

    // Transfer ownership to allocator
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }

    // Called at expiry to settle payout
    function executeOption() external {}
}
