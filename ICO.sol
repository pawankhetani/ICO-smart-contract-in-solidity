// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract ERC20 {
    event Transfer(address from, address to, uint noOfTokens);
    event Approval(address owner, address sender, uint noOfTokens);
    event Log(address);

    address owner;
    uint totalTokens;
    uint icoEndTime;
    mapping(address => uint) public investorTokens;
    mapping(address => mapping(address => uint)) public approved;

    constructor(uint _totalTokens, uint _icoEndTime) {
        totalTokens = _totalTokens;
        owner = msg.sender;
        investorTokens[owner] = totalTokens;
        icoEndTime = block.timestamp + 10 minutes;
    }

    modifier notNull(address addr) {
        require(addr != address(0), "Address null");
        _;
    }

    function getTotalSupply() external view returns(uint) {
        return(totalTokens);
    }

    function transfer(address to, uint noOfTokens) public payable notNull(to) {
        require(noOfTokens <= investorTokens[owner] && noOfTokens > 0, "Not enough tokens hehe");
        investorTokens[owner] -= noOfTokens;
        investorTokens[to] += noOfTokens;

        emit Transfer(msg.sender, to, noOfTokens);
    }

    function approve(address spender, uint noOfTokens) public notNull(spender) {
        require(noOfTokens > 0 && noOfTokens <= investorTokens[msg.sender], "Not enough tokens");
        approved[msg.sender][spender] += noOfTokens;

        emit Approval(msg.sender, spender, noOfTokens);
    }

    function transferFrom(address from, address to, uint noOfTokens)  public payable notNull(from) notNull(to) {
        require(approved[from][msg.sender] > 0, "Not enough tokens");
        require (noOfTokens > 0 && noOfTokens <= approved[from][msg.sender], "No. of tokens not allowed");
        investorTokens[from] -= noOfTokens;
        approved[from][msg.sender] -= noOfTokens;
        investorTokens[to] += noOfTokens;

        emit Transfer(msg.sender, to, noOfTokens);
    }

    function allowance(address _owner, address spender) public view returns(uint) {
        return(approved[_owner][spender]);
    }

    function balance(address _owner) public view returns(uint) {
        return (investorTokens[_owner]);
    }

}

contract ICO {
    event Log(address);
    uint raisedFunds;
    address payable owner;
    uint icoStartTime;
    uint icoEndTime;
    uint minFunds;
    uint rate;
    ERC20 public token;

    //mapping(address => uint) public investors;

    modifier onlyOwner() {
        require(owner == msg.sender, "Not Owner");
        _;
    }

    modifier isTimeStarted() {
        require(block.timestamp > icoStartTime, "ICO not started yet");
        _;
    }

    modifier isTimePassed() {
        require(icoEndTime > block.timestamp, "ICO time not ended yet");
        _;
    }

    receive() payable external isTimeStarted {  
        buyTokens(msg.value);
    }

    constructor(uint _icoStartTime, uint _icoEndTime, uint _minFunds, address _erc20, uint _rate) {
        require(_icoStartTime != 0 && _icoEndTime !=0 && _icoStartTime < _icoEndTime, "wrong start or end time");
            require(_minFunds !=0, "Invalid min funds");
        require(_rate > 0, "ivalid input rate");

        owner = payable(msg.sender);
        icoStartTime = block.timestamp;
        icoEndTime = icoStartTime + 10 minutes;
        token = ERC20(_erc20);
        minFunds = _minFunds;
        rate = _rate;
    }

    function buyTokens(uint amount) public payable isTimeStarted {
        require(amount > 0  && msg.value == amount, "Invalid eth amount");
        raisedFunds += msg.value;
        token.transfer(msg.sender, msg.value*rate);
    }

    function withdraw() payable public onlyOwner isTimePassed {
        require(address(this).balance >= minFunds, "ICO not succeded");
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function refund() payable public isTimePassed {
        require(token.balance(msg.sender) > 0, "Not an investor");
        require(address(this).balance < minFunds, "ICO succeded, cannot refund");
        (bool sent, ) = msg.sender.call{value: token.balance(msg.sender)/rate}("");
        require(sent, "Failed to send Ether");
    }

    function stopSale() public payable onlyOwner {
        icoEndTime == block.timestamp;
    }
}
