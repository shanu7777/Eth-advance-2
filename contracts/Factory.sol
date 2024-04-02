// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./WalletInsurance.sol";
import "./CollateralProtection.sol";

contract InsuranceFactory {
    mapping(address => address) private userInsuranceContracts;

    mapping(address => address) private userWalletContract;
 event WalletInsuranceCreated(address indexed user, address walletInsurance);
    event CollateralProtectionCreated(address indexed user, address collateralProtection);

    function createWalletInsurance(uint256 _insuredAmount) external {
        require(userWalletContract[msg.sender] == address(0), "You already have an existing insurance contract.");

        WalletInsurance walletInsurance = new WalletInsurance(_insuredAmount);

        userWalletContract[msg.sender] = address(walletInsurance);

        emit WalletInsuranceCreated(msg.sender, address(walletInsurance));
    }

    function getUserWalletContract() external view returns (address) {
        return userWalletContract[msg.sender];
    }
    function createCollateralProtection() external {
        require(userInsuranceContracts[msg.sender] == address(0), "You already have an existing insurance contract.");
        CollateralProtection collateralProtection = new CollateralProtection();
        userInsuranceContracts[msg.sender] = address(collateralProtection);
        emit CollateralProtectionCreated(msg.sender, address(collateralProtection));
    }
    function getUserInsuranceContracts() external view returns (address) {
        return userInsuranceContracts[msg.sender];
    }
}
