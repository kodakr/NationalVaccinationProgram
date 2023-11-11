// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "src/CertificateToken.sol";

//@author: https://twitter.com/Kodak_Rome

/**
 * @title The National Vaccination Program - A Lifesaving Revolution
 * @dev In a world plagued by the relentless outbreak of a deadly disease, three members of a small, close-knit community found themselves caught in the whirlwind of a crisis. This is their story.

// Sarah: It's been weeks, and the disease outbreak shows no sign of slowing down. We desperately need vaccinations, but the nearest vaccine center is in a faraway countryside. I can't afford the travel expenses!

// John: I hear you, Sarah. It's not just about the cost; it's also the fear of missing a dose. Remember Aunt Mary? She missed a dose of her vaccine, and we all know what happened.

// Nnamdi: I'm equally concerned, John. It's hard to keep track of our doses and ensure we complete the regimen. We need a solution, and we need it now.

// Sarah: But what can we do? It feels like we're trapped in this nightmare.

// John: Wait, I heard about this National Vaccination Program project. They're using smart contracts to issue NFT certificates on vaccination Completion. It prevents multiple enrollments, so there's no need to worry about fraud.

// Nnamdi: That's amazing, John! But how does it help us with the multi-dose vaccine tracking problem?

// John: Well, Nnamdi, the smart contract also keeps track of our vaccination history. It's like having a personal health assistant, reveals 2 us our next dose.

// Sarah: And what about those who complete the regimen?

// John: That's the best part, Sarah. The program incentivizes patients with Program tokens for completing all their doses. It's a reward for dedication to our health.

// Nnamdi: It sounds like the lifeline we've been waiting for! This National Vaccination Program is not just about vaccinations; it's about saving lives and protecting our community.

// Sarah: Let's support it, guys! It's our way out of this nightmare and into a healthier future.

// John: I couldn't agree more, Sarah. Let's participate in this revolutionary program to our community and make a difference in the fight against this disease.

// Nnamdi: To a brighter, healthier future for all of us!


// Sarah and John: Cheers, Nnamdi! 🌍💉
 */

// Here begins the implementation of the National Vaccination Program smart contract. Together, we can create a safer and healthier world.
contract NationalVaccinationProgram is CertificateToken,ERC20 {
    struct EnrolledPatient {
        string Name;
        address Addr;
        uint DoseCount;
        uint LastDoseTimestamp;
        bool Certified;
    }
    error AdminOnlyFunction(address sender);
    error NotNominatedAdmin(address newadmin);
    error ArrayLengthMismatch();
    error InvalidOrMissingInput();
    error IncentiveAlreadyMinted(uint Bal);
    error EnrollmentCompleted(uint count);
    error PatientNotYetRegistered();
    error NotYetDueForNextDose();
    error DosageNotStarted();

    event adminChanged(address oldAdmin, address newAdmin);
    event EnrollmentIsCompleted(address indexed Patient);

    //address of admin who has a restricted access to some functions
    address Admin;
    // potential future admin. Becomes the admin when claimed
    address newAdmin;
    uint public immutable MAXNUMBEROFDOSES;
    uint public immutable DOSAGETIMEINTERVAL;
    uint public immutable INCENTIVEAMOUNT;
    mapping(address => EnrolledPatient) private patientsDirectory;

    constructor (address _admin, uint _maxNumberOfDoses,uint _doseTimeInterval, uint _amt) CertificateToken("CertificateOfCompleteEnrollment","NTC") ERC20("NAIRA", "NGN") {
        Admin = _admin;
        MAXNUMBEROFDOSES = _maxNumberOfDoses;
        DOSAGETIMEINTERVAL = _doseTimeInterval;
        INCENTIVEAMOUNT = _amt;
    }

    // modifier ensures onlyadmin has access to function
    modifier onlyAdmin {
        if (msg.sender != Admin)revert AdminOnlyFunction(msg.sender);
        _;
    }

    function registerPatient(string[] calldata _names,address[] calldata _patientAddresses) public onlyAdmin returns(bool registered){
        if (_names.length != _patientAddresses.length) revert ArrayLengthMismatch(); //security: Checks if array lengths match
        for (uint i = 0; i < _names.length; i++) {
            if (_patientAddresses[i] == address(0)) revert InvalidOrMissingInput(); //security: Checks if array lengths contains null input. Hence avoids future error. 
            patientsDirectory[_patientAddresses[i]] = EnrolledPatient({
                Name: _names[i],
                Addr: _patientAddresses[i],
                DoseCount: 0,           //NB: `DoseCount` only Updates on vaccine administration.
                LastDoseTimestamp: 0,   //NB: `LastDoseTimestamp` is not updated here. Updated only on vaccine administration.
                Certified: false        //NB: `Certified` isn't updated. Retains default `false`value. Is only true when an enrollled patient has been certified ie Issued Nontransferable NFT. Only at end of successful enrollment
            });
        }
        registered = true;
    }

    function administerVaccine(address _patient) external onlyAdmin returns(bool){
        //cache storage
        EnrolledPatient storage pt = patientsDirectory[_patient];

        //Security: Ensures patient is Registered
        if (pt.Addr == address(0)) revert PatientNotYetRegistered(); 

        //Security: Ensures patient has Remaining doses
        if (pt.DoseCount >= MAXNUMBEROFDOSES) revert EnrollmentCompleted(pt.DoseCount); 

        //Security: Ensures patients' dose is due.
        if (pt.LastDoseTimestamp != 0 && block.timestamp - pt.LastDoseTimestamp < DOSAGETIMEINTERVAL) revert NotYetDueForNextDose();
        
        pt.DoseCount += 1;
        pt.LastDoseTimestamp = block.timestamp;
        if ( pt.DoseCount == MAXNUMBEROFDOSES) {
            pt.Certified = certifyCompletedEnrollment(_patient); // private function returns true
        }
        return true;
    }

    function certifyCompletedEnrollment(address _patient) private returns (bool Certified) {
        uint cacheBal = balanceOf(_patient);
        if (cacheBal != 0) revert IncentiveAlreadyMinted(cacheBal);
        mintCertificate(_patient);
        _mint(_patient, INCENTIVEAMOUNT);
        Certified = true;
        emit EnrollmentIsCompleted(_patient);
    }
    //Checks for only pts who have started the dose
    function checkMyNextDose() public view returns (uint NextDose, bool Due) {
        EnrolledPatient memory pt = patientsDirectory[msg.sender];
        uint cache = pt.LastDoseTimestamp;
        if (cache != uint(0) ){
            NextDose = cache + DOSAGETIMEINTERVAL;
            if (block.timestamp - cache >= DOSAGETIMEINTERVAL){
                Due = true;
            }
        } else {
            revert DosageNotStarted();
        }
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        newAdmin = _newAdmin;
    }
    function acceptAdminRole() external returns (bool) {
        if (msg.sender != newAdmin) revert NotNominatedAdmin(newAdmin);
        emit adminChanged(Admin, newAdmin);
        Admin = newAdmin;
        newAdmin = address(0);
        return true;
    }
    function getMyProfile() public view returns(EnrolledPatient memory){
        return patientsDirectory[msg.sender];
    }
}
