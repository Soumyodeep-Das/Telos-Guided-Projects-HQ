// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid; // The blinded bid
        uint deposit; // The deposit made with the bid
    }
    
    address payable public beneficiary; // The beneficiary of the auction
    
    uint public biddingEnd; // The end time of the bidding phase
    uint public revealEnd; // The end time of the reveal phase
    bool public ended; // Whether the auction has ended
    
    mapping(address => Bid[]) public bids; // Mapping of addresses to their bids

    address public highestBidder; // The address of the highest bidder
    uint public highestBid; // The highest bid amount
    
    mapping(address => uint) pendingReturns; // Pending returns for outbid bidders
    
    event AuctionEnded(address winner, uint highestBid); // Event emitted when the auction ends
    
    error TooEarly(uint time); // Error for actions that are too early
    error TooLate(uint time); // Error for actions that are too late
    error AuctionEndAlreadyCalled(); // Error for calling auctionEnd more than once
    
    modifier onlyBefore(uint time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;        
    }  
    
    modifier onlyAfter(uint time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;          
    }
    
    constructor(
        uint biddingTime,
        uint revealTime,
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingEnd + revealTime;   
    } 
    
    function bid(bytes32 blindedBid) external payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(Bid({
            blindedBid: blindedBid,
            deposit: msg.value
        }));    
    }        
    
    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        bytes32[] calldata secrets
    )
        external
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        uint length = bids[msg.sender].length; 
        
        require(values.length == length);  
        require(fakes.length == length);  
        require(secrets.length == length); 

        uint refund;         
        for (uint i = 0; i < length; i++) {
             Bid storage bidToCheck = bids[msg.sender][i];
             
             (uint value, bool fake, bytes32 secret) =
                    (values[i], fakes[i], secrets[i]);       
             if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
               continue;        
             }       
            refund += bidToCheck.deposit;
            if (!fake && bidToCheck.deposit >= value) {
                if (placeBid(msg.sender, value))
                    refund -= value;
            }
            bidToCheck.blindedBid = bytes32(0);
        }    
        payable(msg.sender).transfer(refund);                                 
    }
    
    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;  
            payable(msg.sender).transfer(amount);     
        }        
    } 
    
    function auctionEnd() external onlyAfter(revealEnd) {
        if (ended) revert AuctionEndAlreadyCalled(); 
        emit AuctionEnded(highestBidder, highestBid); 
        ended = true;   
        beneficiary.transfer(highestBid);                    
    }    
    
    function placeBid(address bidder, uint value) internal
            returns (bool success) { 
        if (value <= highestBid) {
            return false;         
        } 
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;   
        }  
        highestBid = value;
        highestBidder = bidder; 
        return true;                                          
    }
}
