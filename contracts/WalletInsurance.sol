// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract WalletInsurance {
    address public owner;

    uint256 public insuredAmount;

    uint256 public token;

    bool public insured;

    uint256 constant private BasicInsuranceDuration = 90 days;
   uint256 constant private BasicPolicy = 1e9;
    uint256 constant private StandardInsuranceDuration = 180 days;
    uint256 constant private StandardPolicy = 1e8;
    uint256 public insuranceDuration;
    mapping(address => uint256) public balance;
    mapping(address => uint256) public tokenBalance;
    event PaymentReceived(address indexed payer, uint256 amount);
    event Claimed(address indexed claimant, uint256 amount);

    constructor(uint256 _insuredAmount) {
        owner = msg.sender;
        insuredAmount = _insuredAmount;
    }
    function payInsurance() external payable {
        require(!insured, "You are already insured.");
        require(msg.value >= insuredAmount, "The amount provided is not valid.");
        require(block.timestamp > insuranceDuration, "You are unable to make a payment at this time.");
        balance[owner] += msg.value;
        if (msg.value < 1 ether) {
            insuranceDuration = block.timestamp + BasicInsuranceDuration;
            token = (msg.value * 4 * insuranceDuration) / BasicPolicy;
        } else if (msg.value >= 1 ether) {
            insuranceDuration = block.timestamp + StandardInsuranceDuration;
            token = (msg.value * 9 * insuranceDuration) / StandardPolicy;
        }
        insured = true;
        emit PaymentReceived(msg.sender, msg.value);
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "This action can only be performed by the owner of the contract.");
        _;
    }
    function claimInsurance() external payable onlyOwner() {
        require(insured, "You do not have insurance coverage.");
        require(block.timestamp > insuranceDuration, "Your insurance is still valid and has not expired.");
        require(balance[owner] != 0, "The insurance payment has not been made.");
       insured = false;
    tokenBalance[owner] += token;
        (bool sent, ) = (owner).call{value: address(this).balance}("");
        require(sent, "The attempt to send Ether has failed.");

        emit Claimed(msg.sender, address(this).balance);
    }
    function getBalance() external view returns (uint256) {
        return balance[msg.sender];
    }

    function getTokenBalance() external view returns (uint256) {
        return tokenBalance[msg.sender];
    }
}
