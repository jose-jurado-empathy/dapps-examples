// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract Allowance {

    enum PaymentState { Pending, Complete }

    struct Payment {
        uint allowedSince;
        uint amount;
        PaymentState state;
    }

    address public funder;
    address payable public beneficiary;

    Payment[] public payments;

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only beneficiary can call this function");
        _;
    }

    modifier onlyFunder() {
        require(msg.sender == funder, "Only funder can call this function");
        _;
    }

    event PaymentComplete(uint paymentNum);

    constructor(uint numPayments, uint everyNDays, address _beneficiary) payable {
        funder = msg.sender;
        beneficiary = payable(_beneficiary);

        uint paymentAmount = msg.value / numPayments;
        uint paymentDate = block.timestamp;

        for (uint i = 0; i < numPayments; i++) {
            payments.push(Payment({allowedSince: paymentDate, amount: paymentAmount, state: PaymentState.Pending}));
            paymentDate += everyNDays * 1 days;
        }
    }

    function receivePayment(uint paymentNum) public onlyBeneficiary {
        require(payments[paymentNum].state == PaymentState.Pending, "Payment requested is not pending");
        require(payments[paymentNum].allowedSince < block.timestamp, "Payment requested is not allowed yet");

        beneficiary.transfer(payments[paymentNum].amount);
        payments[paymentNum].state = PaymentState.Complete;

        emit PaymentComplete(paymentNum);
    }

    function revoke() public onlyFunder {
        selfdestruct(payable(funder));
    }
}