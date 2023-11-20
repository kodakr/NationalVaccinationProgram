// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
//import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract CertificateToken {
    // Token name
    string public _name;

    // Token symbol
    string public _symbol;

    uint256 public certificateCount;
    //
    mapping(uint256 certificateID => address) private patients;

    mapping(address patient => bool) private CertifiedPatients;
    /**
     * @dev Initializes the Certificate Token contract with a given name and symbol.
     */

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    /**
    @dev Checks whether a patient is already certified.
     */
    function isCertified(address patient) public view returns (bool) {
        return bool(CertifiedPatients[patient]);
    }

    /**
    @dev Mints a certificate for the _patient, incrementing the certificateCount.
     */
    function mintCertificate(address _patient) public {
        patients[++certificateCount] = _patient;
        CertifiedPatients[_patient] = true;
    }
}
