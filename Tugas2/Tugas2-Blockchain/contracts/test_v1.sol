pragma solidity ^0.8.7;

contract helloWorld{

    uint256 totalCoin;

    function addCoin(uint256 nCoin) public{
        totalCoin += nCoin;
    }

    //view; for non transaction (not changing the state on the blockchain (No Gas Needed)
    //return; this function will return data as the result

    function viewTotalCoin() public view returns(uint){
        return totalCoin;
    }
}