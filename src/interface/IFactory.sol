// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IFactory {
    function deploy(
        address _admin,
        uint256 _maxNumberOfDoses,
        uint256 _doseTimeInterval,
        uint256 _amt,
        string  memory _certificateTokenName,
        string memory _certificateTokenSymbol,
        string memory _erc20Name,
        string memory _ercSymbol
    ) external returns (address program);

}



