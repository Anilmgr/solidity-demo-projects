// SPDX-License-Identifier: GPL-3.0

pragma solidity > 0.8.0 <= 0.9.0;

interface ERC20Interface{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

contract JacksCoin is ERC20Interface{
    string public override name = "JacksCoin";
    string public override symbol = "JC";
    uint8 public override decimals = 0;
    uint256 public override totalSupply;
    address public founder;
    mapping(address=>uint256) public balances;
    mapping(address=>mapping(address=>uint256)) allowed; 

    constructor(){
        totalSupply = 300000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256){
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public virtual override returns (bool){
        require(balances[msg.sender] >= _value);

        balances[_to] += _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    } 

    function allowance(address _owner, address _spender) public view override returns (uint256){
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public override returns (bool){
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool){
        require(allowed[_from][_to] >= _value);
        require(balances[_from] >= _value);
        require(_value > 0);

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][_to] -= _value;

        return true;
    }

}

contract JacksCoinICO is JacksCoin{
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.0001 ether; // 1 ETH = 10000 JC
    uint public hardCap = 300 ether;
    uint public raisedAmount;
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800;
    uint public tokenTradedStart = saleEnd + 604800;
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.01 ether;

    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;

    constructor(address payable _deposit){
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }

    modifier onlyAdmin{
        require(msg.sender == admin);
        _;
    }

    function halt() public onlyAdmin{
        icoState = State.halted;
    }

    function resume() public onlyAdmin{
        icoState = State.running;
    }

    function changeDepositAddress(address payable _deposit) public onlyAdmin{
        deposit = _deposit;
    }

    function getCurrentState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        } else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }

    event Invest(address indexed investor, uint value, uint tokens);

    function invest() payable public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);

        uint tokens = msg.value / tokenPrice;
        
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        deposit.transfer(msg.value);

        emit Invest(msg.sender, msg.value, tokens);
        return true;

    }

    receive() payable external{
        invest();
    }


   function transfer(address _to, uint256 _value) public override returns (bool){
       require(block.timestamp > tokenTradedStart);
       JacksCoin.transfer(_to,_value); //super.transfer(_to,_value);
       return true;
   }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool){
       require(block.timestamp > tokenTradedStart);
        JacksCoin.transferFrom(_from,_to,_value);
        return true;
    }

    function burn() public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }
}