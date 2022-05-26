// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint storedData; //mendeklarasikan variabel state yang disebut storedData bertipe uint

    function set(uint x) public {//fungsi set 
        storedData = x;
    }

    function get() public view returns (uint) {//fungsi get
        return storedData;
    }
}