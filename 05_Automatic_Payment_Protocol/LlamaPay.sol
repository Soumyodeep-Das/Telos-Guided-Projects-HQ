// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MyToken} from "./MyToken.sol";

interface IERC20WithDecimals {
    function decimals() external view returns (uint8);
}

contract LlamaPay {
    using SafeERC20 for IERC20;

    struct Payer {
        uint40 lastPayerUpdate;
        uint216 totalPaidPerSec;
    }

    mapping (bytes32 => uint) public streamToStart;
    mapping (address => Payer) public payers;
    mapping (address => uint) public balances;
    IERC20 public token;
    uint public DECIMALS_DIVISOR;

    event StreamCreated(address indexed from, address indexed to, uint216 amountPerSec, bytes32 streamId);
    event Withdraw(address indexed from, address indexed to, uint216 amountPerSec, bytes32 streamId, uint amount);
    event PayerDeposit(address indexed from, uint amount);

    constructor(address myToken){
        token = IERC20(myToken);
        uint8 tokenDecimals = IERC20WithDecimals(address(token)).decimals();
        DECIMALS_DIVISOR = 10**(20 - tokenDecimals);
    }

    function deposit(uint amount) public {
        balances[msg.sender] += amount * DECIMALS_DIVISOR;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit PayerDeposit(msg.sender, amount);
    }

    function getStreamId(address from, address to, uint216 amountPerSec) public pure returns (bytes32){
        return keccak256(abi.encodePacked(from, to, amountPerSec));
    }

    function createStream(address to, uint216 amountPerSec) public {
        bytes32 streamId = getStreamId(msg.sender, to, amountPerSec);
        require(amountPerSec > 0, "amountPerSec can't be 0");
        require(streamToStart[streamId] == 0, "stream already exists");
        streamToStart[streamId] = block.timestamp;

        Payer storage payer = payers[msg.sender];
        uint totalPaid;
        uint delta = block.timestamp - payer.lastPayerUpdate;

        unchecked {
            totalPaid = delta * uint(payer.totalPaidPerSec);
        }
        balances[msg.sender] -= totalPaid; 

        payer.lastPayerUpdate = uint40(block.timestamp);
        payer.totalPaidPerSec += amountPerSec;
        emit StreamCreated(msg.sender, to, amountPerSec, streamId);
    }


    function _withdraw(address from, address to, uint216 amountPerSec) private returns (uint40 lastUpdate, bytes32 streamId, uint amountToTransfer) {
        streamId = getStreamId(from, to, amountPerSec);
        require(streamToStart[streamId] != 0, "stream doesn't exist");

        Payer storage payer = payers[from];
        uint totalPayerPayment;
        uint payerDelta = block.timestamp - payer.lastPayerUpdate;
        unchecked{
            totalPayerPayment = payerDelta * uint(payer.totalPaidPerSec);
        }

        uint payerBalance = balances[from];
        if(payerBalance >= totalPayerPayment){
            unchecked {
                balances[from] = payerBalance - totalPayerPayment;   
            }
            lastUpdate = uint40(block.timestamp);
        } else {
            unchecked {
                uint timePaid = payerBalance/uint(payer.totalPaidPerSec);
                lastUpdate = uint40(payer.lastPayerUpdate + timePaid);
                balances[from] = payerBalance % uint(payer.totalPaidPerSec);
            }
        }
        uint delta = lastUpdate - streamToStart[streamId]; 
        unchecked {
            amountToTransfer = (delta*uint(amountPerSec))/DECIMALS_DIVISOR;
        }
        emit Withdraw(from, to, amountPerSec, streamId, amountToTransfer);
    }


    function withdraw(address from, address to, uint216 amountPerSec) external {
        (uint40 lastUpdate, bytes32 streamId, uint amountToTransfer) = _withdraw(from, to, amountPerSec);
        streamToStart[streamId] = lastUpdate;
        payers[from].lastPayerUpdate = lastUpdate;
        token.safeTransfer(to, amountToTransfer);
    }


    function getPayerBalance(address payerAddress) external view returns (int) {
        Payer storage payer = payers[payerAddress];
        int balance = int(balances[payerAddress]);
        uint delta = block.timestamp - payer.lastPayerUpdate;
        int res = (balance - int(delta*uint(payer.totalPaidPerSec)))/int(DECIMALS_DIVISOR);
        return res;
    }
}