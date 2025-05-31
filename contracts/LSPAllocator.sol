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

    }

    // View function for the amount of capital still liquid and available for offset
    function availableForOffset() external view returns (uint256) {
 
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

    }

    // Placeholder for potential collateral substitution when offset() is triggered
    function backstopWithCollateral(uint256 nectNeeded, address collateralToken, uint256 value) external {

    }

    // Settle an option after expiry
    function settleOption(uint index) external onlyOwner {

    }

    // Manually return unused capital to the LSP
    function returnToLSP(uint amount) external onlyOwner {

    }

    // Withdraw collected premiums and return them proportionally to LSP and Treasury
    function withdrawPremiums() external onlyOwner {

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
        
    }

    // Allow updating premium share distribution
    function updatePremiumDistribution(uint256 _lspShare, uint256 _treasuryShare) external onlyOwner {

    }

    // Set new treasury address
    function setTreasury(address _treasury) external onlyOwner {

    }
}
