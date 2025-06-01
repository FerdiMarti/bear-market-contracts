// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OptionToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBonzoPool.sol";
import "./interfaces/IBonzoPoolAddressesProvider.sol";

contract YieldBearingOptionToken is OptionToken {
    IBonzoPool public immutable bonzoPool;
    uint256 public totalYield;
    bool public yieldWithdrawn;

    event YieldGenerated(uint256 amount);
    event YieldWithdrawn(address indexed recipient, uint256 amount);

    constructor(
        OptionType _optionType,
        bytes32 _paymentTokenPythAssetId,
        address _pythAddress,
        uint256 _strikePrice,
        uint256 _expiration,
        uint256 _executionWindowSize,
        uint256 _premium,
        uint256 _amount,
        address _paymentToken,
        uint256 _collateral,
        address _bonzoPoolAddressesProvider
    ) 
        OptionToken(
            _optionType,
            _paymentTokenPythAssetId,
            _pythAddress,
            _strikePrice,
            _expiration,
            _executionWindowSize,
            _premium,
            _amount,
            _paymentToken,
            _collateral
        )
    {
        // Get Bonzo Finance Pool from addresses provider
        IBonzoPoolAddressesProvider provider = IBonzoPoolAddressesProvider(_bonzoPoolAddressesProvider);
        bonzoPool = IBonzoPool(provider.getPool());

        // Approve Bonzo Finance Pool to spend collateral
        IERC20(paymentToken).approve(address(bonzoPool), type(uint256).max);

        // Deposit collateral to Bonzo Finance
        bonzoPool.deposit(
            address(paymentToken),
            collateral,
            address(this),
            0 // referral code
        );
    }

    function _fixPrice() internal override {
        // Withdraw collateral from Bonzo Finance before fixing price
        if (!yieldWithdrawn) {
            uint256 aTokenBalance = IERC20(bonzoPool.getReserveAToken(address(paymentToken))).balanceOf(address(this));
            if (aTokenBalance > 0) {
                bonzoPool.withdraw(
                    address(paymentToken),
                    aTokenBalance,
                    address(this)
                );
                
                // Calculate yield generated
                uint256 currentBalance = IERC20(paymentToken).balanceOf(address(this));
                if (currentBalance > collateral) {
                    totalYield = currentBalance - collateral;
                    emit YieldGenerated(totalYield);
                }
            }
        }
        
        super._fixPrice();
    }

    //This version enables the creator of the option to withdraw all yield. 
    //It would also be possible to split yield between creator and option buyers or keep for the protocol.
    function withdrawYield() external onlyOwner {
        require(!yieldWithdrawn, "Yield already withdrawn");
        require(totalYield > 0, "No yield to withdraw");
        
        yieldWithdrawn = true;
        require(
            IERC20(paymentToken).transfer(owner(), totalYield),
            "Yield transfer failed"
        );
        
        emit YieldWithdrawn(owner(), totalYield);
    }
}
