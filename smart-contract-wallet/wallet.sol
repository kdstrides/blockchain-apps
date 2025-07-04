// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

contract Wallet {
  address payable public owner;
  address payable public nextOwner;

  uint public guardianResetCount;
  uint public constant confirmationFromGuardiansToReset = 3;

  mapping(address => uint) public allowance;
  mapping(address => bool) public guardians;
  mapping(address => bool) public isAllowedToSend;
  mapping(address => mapping(address => bool)) public nextOwnerGuardiansVoted;

  constructor() {
    owner = payable(msg.sender);
  }

  function setGuardian(address _guardian, bool _isGuardian) public {
    require(msg.sender == owner, 'Only owner can set guardian');

    guardians[_guardian] = _isGuardian;
  }

  function setAllowance(address _for, uint _amount) public {
    require(msg.sender == owner, 'Only owner can set allowance');

    allowance[_for] = _amount;
    isAllowedToSend[_for] = _amount > 0;
  }

  function proposeNewOwner(address payable _newOwner) public {
    require(guardians[msg.sender], 'Only guardians can propose new owner');
    require(
      nextOwnerGuardiansVoted[msg.sender][_newOwner] == false,
      'Guardian already voted'
    );

    nextOwnerGuardiansVoted[msg.sender][_newOwner] = true;

    if (nextOwner != owner) {
      nextOwner = _newOwner;
      guardianResetCount = 0;
    }

    guardianResetCount++;

    if (guardianResetCount >= confirmationFromGuardiansToReset) {
      owner = nextOwner;
      nextOwner = payable(address(0));
      guardianResetCount = 0;
    }
  }

  function resetOwner() public {
    require(guardians[msg.sender], 'Only guardians can reset owner');

    require(
      guardianResetCount >= confirmationFromGuardiansToReset,
      'Not enough guardians to reset owner'
    );

    owner = nextOwner;
  }

  function transfer(
    address payable _to,
    uint256 _amount,
    bytes memory _data
  ) public returns (bytes memory response) {
    if (isAllowedToSend[msg.sender]) {
      require(
        isAllowedToSend[msg.sender],
        'Recipient is not allowed to receive funds'
      );
      require(allowance[msg.sender] >= _amount, 'Allowance exceeded');
    }

    (bool success, bytes memory _response) = _to.call{ value: _amount }(_data);

    require(success, 'Transfer failed');

    return _response;
  }

  receive() external payable {}

  fallback() external payable {}
}
