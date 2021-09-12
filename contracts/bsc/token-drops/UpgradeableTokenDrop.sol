// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../tokens/IBEP20.sol";
import "../../utils/math/SafeMath.sol";
import "../../utils/storage/OwnedUpgradeableStorage.sol";
import "../../utils/Claimable.sol";

contract UpgradebleTokenDrop is OwnedUpgradeableStorage, Claimable {
    using SafeMath for uint;

    event DropSent(uint total, address tokenAddress);
    event ClaimedTokens(address token, address owner, uint balance);

    modifier hasFee() {
        if (currentFee(msg.sender) > 0) {
            require(msg.value >= currentFee(msg.sender));
        }
        _;
    }

    receive() external payable{}
    fallback() external payable{}

    function initialize(address _owner) public {
        require(!_initialized());
        transferOwnership(_owner);
        setArrayLimit(200);
        setDiscountStep(0.00005 ether);
        setFee(0.05 ether);
        boolStorage[keccak256("bsf_drop_init")] = true;
    }

    function _initialized() private view returns (bool){
        return boolStorage[keccak256("bsf_drop_init")];
    }

    function initialized() external view returns (bool) {
        return _initialized();
    }

    function _txCount(address customer) internal view returns(uint){
        return uintStorage[keccak256(abi.encodePacked("bsf_drop_tx_count", customer))];
    }
 
    function txCount(address customer) external view returns(uint) {
        return _txCount(customer);
    }

    function _arrayLimit() internal view returns(uint){
        return uintStorage[keccak256("bsf_drop_limit_array")];
    }

    function arrayLimit() external view returns(uint) {
        return _arrayLimit();
    }

    function setArrayLimit(uint _newLimit) public onlyOwner {
        require(_newLimit != 0);
        uintStorage[keccak256("bsf_drop_limit_array")] = _newLimit;
    }

    function _discountStep() internal view returns(uint){
        uintStorage[keccak256("bsf_drop_step_discount")];
    }

    function discountStep() external view returns(uint) {
        return uintStorage[keccak256("bsf_drop_step_discount")];
    }

    function setDiscountStep(uint _newStep) public onlyOwner {
        require(_newStep != 0);
        uintStorage[keccak256("bsf_drop_step_discount")] = _newStep;
    }

    function fee() public view returns(uint) {
        return uintStorage[keccak256("bsf_drop_fee")];
    }

    function currentFee(address _customer) public view returns(uint) {
        if (fee() > discountRate(msg.sender)) {
            return fee().sub(discountRate(_customer));
        } else {
            return 0;
        }
    }

    function setFee(uint _newStep) public onlyOwner {
        require(_newStep != 0);
        uintStorage[keccak256("bsf_drop_fee")] = _newStep;
    }

    function discountRate(address _customer) public view returns(uint) {
        uint count = _txCount(_customer);
        return count.mul(_discountStep());
    }

    function multisendToken(address token, address[] calldata _contributors, uint[] calldata _balances) public hasFee payable {
        if (token == 0x000000000000000000000000000000000000bEEF){
            multisendEther(_contributors, _balances);
        } else {
            uint total = 0;
            require(_contributors.length <= _arrayLimit());
            IBEP20 IBEP20token = IBEP20(token);
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
                IBEP20token.transferFrom(msg.sender, _contributors[i], _balances[i]);
                total += _balances[i];
            }
            setTxCount(msg.sender, _txCount(msg.sender).add(1));
            emit DropSent(total, token);
        }
    }

    function multisendEther(address[] calldata _contributors, uint[] calldata _balances) public payable {
        uint total = msg.value;
        uint fee_ = currentFee(msg.sender);
        require(total >= fee_);
        require(_contributors.length <= _arrayLimit());
        total = total.sub(fee_);
        uint i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            payable(_contributors[i]).transfer(_balances[i]);
        }
        setTxCount(msg.sender, _txCount(msg.sender).add(1));
        emit DropSent(msg.value, 0x000000000000000000000000000000000000bEEF);
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IBEP20 IBEP20token = IBEP20(_token);
        uint balance = IBEP20token.balanceOf(address(this));
        IBEP20token.transfer(owner(), balance);
        emit ClaimedTokens(_token, owner(), balance);
    }
    
    function setTxCount(address customer, uint txCount_) private {
        uintStorage[keccak256(abi.encodePacked("bsf_drop_tx_count", customer))] = txCount_;
    }
}