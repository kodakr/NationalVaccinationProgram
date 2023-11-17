// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {NationalVaccinationProgram} from "./NationalVaccinationProgram.sol";

contract Factory {
    mapping(bytes32 => address) register;
    uint public counter;

    
    function deploy(
        address _admin,
        uint256 _maxNumberOfDoses,
        uint256 _doseTimeInterval,
        uint256 _amt,
        string _certificateTokenName,
        string _certificateTokenSymbol,
        string _erc20Name,
        string _ercSymbol
    ) public returns (address program) {
        bytes32 _id = generateUniqueId();
        program = address(
            new NationalVaccinationProgram{salt: _id}(_admin,_maxNumberOfDoses,_doseTimeInterval,_amt,_certificateTokenName,_certificateTokenSymbol,_erc20Name,_ercSymbol)
        );
        register[_id] = program;
    }

    function generateUniqueId() internal returns (bytes32) {
        bytes32 cache = keccak256(abi.encode(++counter));
        while ( register[cache] != address(0) ) {
            cache = keccak256(abi.encode(++counter));
        }
        return cache;
    }
}
