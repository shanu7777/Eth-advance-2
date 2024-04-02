// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract CollateralProtection {
    address public owner;

    uint256 public collateralThreshold;

    struct LoanPolicy {
        uint256 loanAmount;
      uint256 collateralThreshold;

        uint256 loanDuration;
        uint256 loanOwed;
        uint256 wallet;
        bool paid;
    }
    mapping(address => uint256) public loanCollateral;

    mapping(address => LoanPolicy) public loan;

    event LoanCreated(address indexed borrower, uint256 loanAmount, uint256 collateralAmount);

    event CollateralReturned(address indexed borrower, uint256 collateralAmount);

    constructor() {
        owner = tx.origin; // Set the contract owner to the deployer's address
    }


    // Amount for the basic loan plan
    uint256 private constant BasicPlan = 1 ether;

    uint256 private constant BasicPlanDuration = 90 days;

    uint256 private constant PremiumPlan = 2 ether;

    uint256 private constant PremiumPlanDuration = 180 days;

    modifier onlyOwner() {
        require(msg.sender == owner, "This action can only be performed by the owner of the contract.");
        _;
    }

    function createLoan(uint256 loanAmount, uint256 collateralAmount) external onlyOwner {
        require(loanAmount > 0, "The loan amount should be higher than zero.");
        require(collateralAmount > 0, "The collateral amount needs to exceed zero.");

        require(loan[msg.sender].loanAmount == 0, "A loan with the same details already exists.");

        if (loanAmount > BasicPlan) {
            loan[owner] = LoanPolicy(
                loanAmount,
                collateralAmount,
                block.timestamp + PremiumPlanDuration,
                loanAmount + (loanAmount * 20) / 100,
                0,
                false
            );
        } else if (loanAmount <= BasicPlan) {
            loan[owner] = LoanPolicy(
                loanAmount,
                collateralAmount,
                block.timestamp + BasicPlanDuration,
                loanAmount + (loanAmount * 10) / 100,
                0,
                false
            );
        }

        loanCollateral[msg.sender] = collateralAmount;

        emit LoanCreated(msg.sender, loanAmount, collateralAmount);
    }

    function collectLoan() external payable {
        require(loanCollateral[owner] != 0, "There is no collateral associated with your account.");

        require(loan[owner].wallet == 0, "The balance in your wallet must be zero.");

        require(loan[owner].collateralThreshold >= loan[owner].loanAmount, "The amount of collateral you have is insufficient.");

        require(!loan[owner].paid, "The loan has not been paid out yet.");

        (bool sent,) = (owner).call{value: loan[owner].loanAmount}("");
        require(sent, "The attempt to send Ether has failed.");

        loan[owner].wallet += loan[owner].loanAmount;
    }

    function payLoan() external payable {
        require(loan[owner].loanOwed > 0, "There is no loan available to be paid.");

        require(msg.value >= loan[owner].loanOwed, "The provided amount is not sufficient.");

        require(!loan[owner].paid, "The loan has not been paid out yet.");

        payable(address(this)).transfer(msg.value);

        loan[owner].loanOwed -= msg.value;

        loanCollateral[msg.sender] = 0;

        emit CollateralReturned(owner, msg.value);
    }

    receive() payable external {}
}
