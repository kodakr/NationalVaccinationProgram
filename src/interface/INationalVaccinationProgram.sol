// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INationalVaccinationProgram {
    struct EnrolledPatient {
        string Name;
        address Addr;
        uint256 DoseCount;
        uint256 LastDoseTimestamp;
        bool Certified;
    }

    function registerPatient(string[] calldata _names, address[] calldata _patientAddresses)
        external
        returns (bool registered);
    function administerVaccine(address _patient) external returns (bool);
    function checkMyNextDose() external view returns (uint256 NextDose, bool Due);
    function proposeChangeAdmin(address _newAdmin) external;
    function acceptAdminRole() external returns (bool);
    function getMyProfile() external view returns (EnrolledPatient memory);
}
