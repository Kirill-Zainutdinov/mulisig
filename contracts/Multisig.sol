// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "hardhat/console.sol";

contract Multisig {

    mapping(address => bool) admins;
    uint256 adminsCount;
    uint256 public nonce;

    constructor(address[] memory _admins){
        adminsCount = _admins.length;
        for(uint256 i = 0; i < adminsCount; i++){
            admins[_admins[i]] = true;
        }
    }


    function verify(
        uint256 _nonce,
        address target,
        bytes calldata payload,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) 
        public
    {
        // проверяем, что nonce правильный
        require(_nonce == nonce, "Bad nonce");
        // увеличиваем nonce
        nonce++;

        // проверяем, что массивы одинаковой длины
        require(v.length == r.length && r.length == s.length, "Bad arrays");

        // получаем хеш сообщения, который подписывался
        bytes32 messageHash = getMessageHash(_nonce, target, payload);

        // получаем правильных подписей
        uint256 signed = _verify(messageHash, v, r, s);

        // проверяем, что подписей достаточно
        require(signed > adminsCount / 2, "Not enough signatures");

        // делаем вызов
        (bool success,) = target.call(payload);
        require(success);
    }

    function _verify(
        bytes32 messageHash,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) 
        internal
        view
        returns(uint256)
    {
        // количество правильных подписей
        uint256 signed = 0;
        // массив админов, которые подписали
        address[] memory adrs = new address[](v.length);
        // в этом цикле восстанавливаем адреса и считаем сколько там админов
        for (uint256 i = 0; i < v.length; i++){
            // восстанавливаем очередную подпись
            address adr = ecrecover(messageHash, v[i], r[i], s[i]);
            // если она есть в списке админов
            if(admins[adr] == true){
                // проверяем нет ли уже этой подписи среди подписавших
                bool check = true;
                for(uint256 j = 0; j < adrs.length; j++){
                    if(adrs[i] == adr){
                        check = false;
                        break;
                    }
                }
                if(check){
                    adrs[signed] = adr;
                    signed++;
                }
            }
        }
        return signed;
    }

    function getMessageHash(
        uint256 _nonce,
        address target,
        bytes calldata payload
    ) 
        internal view returns(bytes32)
    {
        bytes memory message = abi.encodePacked(_nonce, address(this), target, payload);
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        bytes memory digest = abi.encodePacked(prefix, toBytes(message.length), message);
        return keccak256(digest);
    }

    // это другой вариант, когда сообщение перед подписью хешируется
    function getMessageHash2(
        uint256 _nonce,
        address target,
        bytes calldata payload
    ) 
        internal view returns(bytes32)
    {
        bytes32 message = keccak256(abi.encodePacked(_nonce, address(this), target, payload));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes memory digest = abi.encodePacked(prefix, message);
        return keccak256(digest);
    }

    // Функция для перевода числа в строку
    function toBytes(uint256 value) internal pure returns(bytes memory) {
        uint256 temp = value;
        uint256 digits;
        do {
            digits++;
            temp /= 10;
        } while (temp != 0);
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return buffer;
    }
}
