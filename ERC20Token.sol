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
    uint8 public override decimals = 5;
    uint256 public override totalSupply;
    address public founder;
    mapping(address=>uint256) public balances;
    mapping(address=>mapping(address=>uint256)) allowed; 

    constructor(uint256 _totalSupply){
        totalSupply = _totalSupply;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256){
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public override returns (bool){
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

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool){
        require(allowed[_from][_to] >= _value);
        require(balances[_from] >= _value);
        require(_value > 0);

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][_to] -= _value;

        return true;
    }


}