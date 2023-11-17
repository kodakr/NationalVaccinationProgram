// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
//import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract CertificateToken {
    // Token name
    string public _name;

    // Token symbol
    string public _symbol;

    uint256 public certificateCount;

    mapping(uint256 certificateID => address) private patients;

    mapping(address patient => bool) private CertifiedPatients;
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function isCertified(address patient) public view returns (bool) {
        return bool(CertifiedPatients[patient]);
    }

    function mintCertificate(address _patient) public {
        patients[++certificateCount] = _patient;
        CertifiedPatients[_patient] = true;
    }
}
