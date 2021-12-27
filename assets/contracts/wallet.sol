pragma solidity 0.6.6;

contract Wallet {
    int balance;
    int[] history;

    constructor() public {
        balance = 0;
    }

    function getBalance() view public returns(int) {
        return balance;
    }

    function getHistory() view public returns(int[] memory) {
        return history;
    }

    function resetHistory() public {
        delete history;
    }

    function depositBalance(int amount) public {
        balance = balance + amount;
        history.push(amount);
    }

    function withdrawBalance(int amount) public {
        balance = balance - amount;
        history.push(-amount);
    }
}