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

    address public owner;
    address public lsp;
    address public optionImplementation;
    address public paymentToken;
    uint256 public bufferRatio = 30; // % of capital reserved for offset() needs
    uint256 public lspPremiumShare = 80;
    uint256 public treasuryPremiumShare = 20;
    address public treasury;

    struct OptionPosition {
        address contractAddress;
        uint256 amount;
        uint256 expiry;
        bool settled;
    }

    OptionPosition[] public activeOptions;

    uint256 public totalAllocated;
    uint256 public usedForOptions;
    uint256 public totalPremiumsCollected;

    constructor(address _lsp, address _optionImplementation, address _paymentToken) {
        owner = msg.sender;
        lsp = _lsp;
        optionImplementation = _optionImplementation;
        paymentToken = _paymentToken;
        treasury = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not allowed");
        _;
    }

    // Allows LSP to allocate NECT to the module
    function allocate(uint256 amount) external {
        require(msg.sender == lsp, "Only LSP can allocate");
        IERC20(paymentToken).transferFrom(msg.sender, address(this), amount);
        totalAllocated += amount;
    }

    // Returns the currently available NECT that is still within the reserved buffer
    function availableForOffset() external view returns (uint256) {
        uint256 reserved = (totalAllocated + usedForOptions) * bufferRatio / 100;
        uint256 used = usedForOptions;
        if (reserved > used) {
            return reserved - used;
        }
        return 0;
    }

    // Allows LSP to actively reclaim idle NECT in emergencies (e.g., prior to offset())
    function reclaimLiquidity(uint256 amount) external {
        require(msg.sender == lsp, "Only LSP can reclaim");
        require(amount <= totalAllocated, "Insufficient idle NECT");
        totalAllocated -= amount;
        IERC20(paymentToken).transfer(lsp, amount);
    }

    function writeOption(
        uint strikePrice,
        uint expiration,
        uint executionWindow,
        uint premium,
        uint amount,
        uint8 optionType
    ) public {
        require(
            usedForOptions + amount <= (totalAllocated + usedForOptions) * (100 - bufferRatio) / 100,
            "Buffer exceeded"
        );

        IERC20(paymentToken).transferFrom(msg.sender, address(this), premium);
        totalPremiumsCollected += premium;

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

    function deployOption(
        OptionType optionType,
        uint strike,
        uint expiry,
        uint executionWindow,
        uint premium,
        uint amount
    ) internal returns (address) {
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

        newOption.transferOwnership(address(this));

        IERC20(paymentToken).approve(address(newOption), amount);
        return address(newOption);
    }

    function settleOption(uint index) external onlyOwner {
        OptionPosition storage pos = activeOptions[index];
        require(block.timestamp > pos.expiry, "Not expired");
        require(!pos.settled, "Already settled");

        IOption(pos.contractAddress).executeOption();
        pos.settled = true;
        usedForOptions -= pos.amount;
    }

    function returnToLSP(uint amount) external onlyOwner {
        require(amount <= totalAllocated, "Too much");
        totalAllocated -= amount;
        IERC20(paymentToken).transfer(lsp, amount);
    }

    function withdrawPremiums() external onlyOwner {
        require(totalPremiumsCollected > 0, "No premiums");
        uint256 amount = totalPremiumsCollected;
        totalPremiumsCollected = 0;

        uint256 lspAmount = (amount * lspPremiumShare) / 100;
        uint256 treasuryAmount = amount - lspAmount;

        IERC20(paymentToken).transfer(lsp, lspAmount);
        IERC20(paymentToken).transfer(treasury, treasuryAmount);
    }

    function autoCompoundPremium(
        uint strikePrice,
        uint expiration,
        uint executionWindow,
        uint premium,
        uint amount,
        uint8 optionType
    ) external onlyOwner {
        require(totalPremiumsCollected >= premium, "Insufficient premiums");
        require(
            usedForOptions + amount <= (totalAllocated + usedForOptions) * (100 - bufferRatio) / 100,
            "Buffer exceeded"
        );

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

    function updatePremiumDistribution(uint256 _lspShare, uint256 _treasuryShare) external onlyOwner {
        require(_lspShare + _treasuryShare == 100, "Invalid distribution");
        lspPremiumShare = _lspShare;
        treasuryPremiumShare = _treasuryShare;
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
    }
}

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

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }

    function executeOption() external {}
}
