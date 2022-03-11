//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract HelloWorld{
    string public name = "HelloWorld";
    string public symbol = "HWrd";

    uint public wallet = 0;

    event buyHWrd(uint value);
    event sendHWrd(uint value);

    function myWallet() view public returns(uint){
        return wallet;
    }

    function buy(uint nCoin) public{
        wallet += nCoin;
        emit buyHWrd(wallet);
    }

    function send(uint nCoin) public{
        wallet -= nCoin;
        emit sendHWrd(wallet);
    }
}