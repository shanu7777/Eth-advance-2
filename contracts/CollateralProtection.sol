// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract CollateralProtection {
    address public owner;

    struct LoanPolicy {
        uint256 loanAmount;
        uint256 collateralAmount;
        uint256 loanDuration;
        uint256 loanOwed;
        uint256 wallet;
        bool paid;
    }
    
    mapping(address => uint256) public loanCollateral;
    mapping(address => LoanPolicy) public loans;

    event LoanCreated(address indexed borrower, uint256 loanAmount, uint256 collateralAmount);
    event CollateralReturned(address indexed borrower, uint256 collateralAmount);

    // Constants for loan plans
    uint256 private constant BasicPlan = 1 ether;
    uint256 private constant BasicPlanDuration = 90 days;
    uint256 private constant PremiumPlan = 2 ether;
    uint256 private constant PremiumPlanDuration = 180 days;

    modifier onlyOwner() {
        require(msg.sender == owner, "This action can only be performed by the owner of the contract.");
        _;
    }

    constructor() {
        owner = msg.sender; // Set the contract owner to the deployer's address
    }

    function createLoan(uint256 loanAmount, uint256 collateralAmount) external onlyOwner {
        require(loanAmount > 0, "The loan amount should be higher than zero.");
        require(collateralAmount > 0, "The collateral amount needs to exceed zero.");
        require(loans[msg.sender].loanAmount == 0, "A loan with the same details already exists.");

        LoanPolicy memory newLoan;
        newLoan.loanAmount = loanAmount;
        newLoan.collateralAmount = collateralAmount;

        if (loanAmount > BasicPlan) {
            newLoan.loanDuration = block.timestamp + PremiumPlanDuration;
            newLoan.loanOwed = loanAmount + (loanAmount * 20) / 100;
        } else {
            newLoan.loanDuration = block.timestamp + BasicPlanDuration;
            newLoan.loanOwed = loanAmount + (loanAmount * 10) / 100;
        }

        loans[msg.sender] = newLoan;
        loanCollateral[msg.sender] = collateralAmount;

        emit LoanCreated(msg.sender, loanAmount, collateralAmount);
    }

    function collectLoan() external payable {
        LoanPolicy storage userLoan = loans[msg.sender];
        require(userLoan.collateralAmount != 0, "There is no collateral associated with your account.");
        require(userLoan.wallet == 0, "The balance in your wallet must be zero.");
        require(userLoan.collateralAmount >= userLoan.loanAmount, "The amount of collateral you have is insufficient.");
        require(!userLoan.paid, "The loan has not been paid out yet.");

        (bool sent,) = (msg.sender).call{value: userLoan.loanAmount}("");
        require(sent, "The attempt to send Ether has failed.");

        userLoan.wallet += userLoan.loanAmount;
    }

    function payLoan() external payable {
        LoanPolicy storage userLoan = loans[msg.sender];
        require(userLoan.loanOwed > 0, "There is no loan available to be paid.");
        require(msg.value >= userLoan.loanOwed, "The provided amount is not sufficient.");
        require(!userLoan.paid, "The loan has not been paid out yet.");

        payable(address(this)).transfer(msg.value);
        userLoan.loanOwed -= msg.value;
        loanCollateral[msg.sender] = 0;

        emit CollateralReturned(msg.sender, msg.value);
    }

    receive() payable external {}
}
