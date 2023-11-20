// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "src/CertificateToken.sol";
import { INationalVaccinationProgram } from "./interface/INationalVaccinationProgram.sol";

//@author: https://twitter.com/Kodak_Rome

/**
 * @title The National Vaccination Program - A Lifesaving Revolution
 * @dev In a world plagued by the relentless outbreak of a deadly disease, three members of a small, close-knit community found themselves caught in the whirlwind of a crisis. This is their story.
 *
 * // Sarah: It's been weeks, and the disease outbreak shows no sign of slowing down. We desperately need vaccinations, but the nearest vaccine center is in a faraway countryside. I can't afford the travel expenses!
 *
 * // John: I hear you, Sarah. It's not just about the cost; it's also the fear of missing a dose. Remember Aunt Mary? She missed a dose of her vaccine, and we all know what happened.
 *
 * // Nnamdi: I'm equally concerned, John. It's hard to keep track of our doses and ensure we complete the regimen. We need a solution, and we need it now.
 *
 * // Sarah: But what can we do? It feels like we're trapped in this nightmare.
 *
 * // John: Wait, I heard about this National Vaccination Program project. They're using smart contracts to issue NFT certificates on vaccination Completion. It prevents multiple enrollments, so there's no need to worry about fraud.
 *
 * // Nnamdi: That's amazing, John! But how does it help us with the multi-dose vaccine tracking problem?
 *
 * // John: Well, Nnamdi, the smart contract also keeps track of our vaccination history. It's like having a personal health assistant, reveals 2 us our next dose.
 *
 * // Sarah: And what about those who complete the regimen?
 *
 * // John: That's the best part, Sarah. The program incentivizes patients with Program tokens for completing all their doses. It's a reward for dedication to our health.
 *
 * // Nnamdi: It sounds like the lifeline we've been waiting for! This National Vaccination Program is not just about vaccinations; it's about saving lives and protecting our community.
 *
 * // Sarah: Let's support it, guys! It's our way out of this nightmare and into a healthier future.
 *
 * // John: I couldn't agree more, Sarah. Let's participate in this revolutionary program to our community and make a difference in the fight against this disease.
 *
 * // Nnamdi: To a brighter, healthier future for all of us!
 *
 *
 * // Sarah and John: Cheers, Nnamdi! 🌍💉
 */

// Here begins the implementation of the National Vaccination Program smart contract. Together, we can create a safer and healthier world.
contract NationalVaccinationProgram is INationalVaccinationProgram, CertificateToken, ERC20 {
    error AdminOnlyFunction(address sender);
    error NotNominatedAdmin(address newadmin);
    error ArrayLengthMismatch();
    error InvalidOrMissingInput();
    error IncentiveAlreadyMinted(uint256 Bal);
    error EnrollmentCompleted(uint256 count);
    error PatientNotYetRegistered();
    error NotYetDueForNextDose();
    error DosageNotStarted();

    event adminChanged(address oldAdmin, address newAdmin);
    event EnrollmentIsCompleted(address indexed Patient);

    //address of admin who has a restricted access to some functions
    address Admin;
    // potential future admin. Becomes the admin when claimed
    address newAdmin;
    uint256 public immutable MAXNUMBEROFDOSES;
    uint256 public immutable DOSAGETIMEINTERVAL;
    uint256 public immutable INCENTIVEAMOUNT;
    mapping(address => EnrolledPatient) private patientsDirectory;

    /**
    @dev Initializes the National Vaccination Program with parameters including admin address, maximum number of doses, 
    dose time interval, incentive amount, and Certificate token details.
     */
    constructor(
        address _admin,
        uint256 _maxNumberOfDoses,
        uint256 _doseTimeInterval,
        uint256 _amt,
        string memory _soulboundTokenName,
        string memory _soulboundTokenSymbol,
        string memory _erc20Name,
        string memory _ercSymbol
    ) CertificateToken(_soulboundTokenName, _soulboundTokenSymbol) ERC20(_erc20Name, _ercSymbol) {
        Admin = _admin;
        MAXNUMBEROFDOSES = _maxNumberOfDoses;
        DOSAGETIMEINTERVAL = _doseTimeInterval;
        INCENTIVEAMOUNT = _amt;
    }

    // modifier ensures onlyadmin has access to function
    modifier onlyAdmin() {
        if (msg.sender != Admin) revert AdminOnlyFunction(msg.sender);
        _;
    }

    /**
    @dev Registers patients by mapping their names to their addresses. Only the admin can perform this action. 
    function is designed to take in multi amounts of data and register
     */
    function registerPatient(string[] calldata _names, address[] calldata _patientAddresses)
        public
        onlyAdmin
        returns (bool registered)
    {
        if (_names.length != _patientAddresses.length) revert ArrayLengthMismatch(); //security: Checks if array lengths match
        for (uint256 i = 0; i < _names.length; i++) {
            if (_patientAddresses[i] == address(0)) revert InvalidOrMissingInput(); //security: Checks if array lengths contains null input. Hence avoids future error.
            patientsDirectory[_patientAddresses[i]] = EnrolledPatient({
                Name: _names[i],
                Addr: _patientAddresses[i],
                DoseCount: 0, //NB: `DoseCount` only Updates on vaccine administration.
                LastDoseTimestamp: 0, //NB: `LastDoseTimestamp` is not updated here. Updated only on vaccine administration.
                Certified: false //NB: `Certified` isn't updated. Retains default `false`value. Is only true when an enrollled patient has been certified ie Issued Nontransferable NFT. Only at end of successful enrollment
            });
        }
        registered = true;
    }

    /**
    @dev An admin-only function. admin administeres and updates the record for pationt. Thereby maintaining accountability.
     */
    function administerVaccine(address _patient) external onlyAdmin returns (bool) {
        //cache storage
        EnrolledPatient storage pt = patientsDirectory[_patient];

        //Security: Ensures patient is Registered
        if (pt.Addr == address(0)) revert PatientNotYetRegistered();

        //Security: Ensures patient has Remaining doses
        if (pt.DoseCount >= MAXNUMBEROFDOSES) revert EnrollmentCompleted(pt.DoseCount);

        //Security: Ensures patients' dose is due.
        if (pt.LastDoseTimestamp != 0 && block.timestamp - pt.LastDoseTimestamp < DOSAGETIMEINTERVAL) {
            revert NotYetDueForNextDose();
        }

        pt.DoseCount += 1;
        pt.LastDoseTimestamp = block.timestamp;
        if (pt.DoseCount == MAXNUMBEROFDOSES) {
            pt.Certified = certifyCompletedEnrollment(_patient); // private function returns true
        }
        return true;
    }

    function certifyCompletedEnrollment(address _patient) private returns (bool Certified) {
        uint256 cacheBal = balanceOf(_patient);
        if (cacheBal != 0) revert IncentiveAlreadyMinted(cacheBal);
        mintCertificate(_patient);
        _mint(_patient, INCENTIVEAMOUNT);
        Certified = true;
        emit EnrollmentIsCompleted(_patient);
    }
    
    /**
    @dev Checks the timestamp of the next dose for the caller and whether it is due.
    Checks for only pts who have started the dose
     */
    
    function checkMyNextDose() public view returns (uint256 NextDose, bool Due) {
        EnrolledPatient memory pt = patientsDirectory[msg.sender];
        uint256 cache = pt.LastDoseTimestamp;
        if (cache != uint256(0)) {
            NextDose = cache + DOSAGETIMEINTERVAL;
            if (block.timestamp - cache >= DOSAGETIMEINTERVAL) {
                Due = true;
            }
        } else {
            revert DosageNotStarted();
        }
    }

    // The admin being a restricted role can be altered or confered on someonelse
    function proposeChangeAdmin(address _newAdmin) external onlyAdmin {
        newAdmin = _newAdmin;
    }

    // A proposed (to be Admin) accepts his role by calling this. Only an already proposed address can call
    function acceptAdminRole() external returns (bool) {
        if (msg.sender != newAdmin) revert NotNominatedAdmin(newAdmin);
        emit adminChanged(Admin, newAdmin);
        Admin = newAdmin;
        newAdmin = address(0);
        return true;
    }

    // Allows any registered patient to view profile.
    function getMyProfile() public view returns (EnrolledPatient memory) {
        return patientsDirectory[msg.sender];
    }
}
