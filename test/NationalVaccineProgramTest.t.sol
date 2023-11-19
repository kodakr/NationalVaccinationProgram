// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {NationalVaccinationProgram} from "../src/NationalVaccinationProgram.sol";
import "../src/CertificateToken.sol";
import {NationalVaccinationProgramScript} from "../script/NationalVaccinationProgramScript.s.sol";
import {IFactory} from "../src/interface/IFactory.sol";

struct EnrolledPatient {
    string Name;
    address Addr;
    uint256 LastDoseTimestamp;
    bool Certified;
}
//

contract NationalVaccineProgramTest is Test {
    NationalVaccinationProgram public program;
    address admin = makeAddr("admin");
    address user1 = makeAddr("user1"); // foundry cheatcode to make imaginary address
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");
    string[] names = new string[](2);
    string [] tokenSetup = ["CertificateTokenName","CTF","Naira","NGN"];
    address[] addr = new address[](2);
    uint256 private MaxdoseNumber;
    uint256 private IncentiveAmt;
    uint256 private doseInterval = 3 weeks;
    CertificateToken certificate;
    NationalVaccinationProgramScript script;
    IFactory factory;


    function setUp() public {
        names[0] = "Henry Mitchelle";
        names[1] = "Antony Ruger";
        addr[0] = user1;
        addr[1] = user2;
        IncentiveAmt = 1 ether;
        MaxdoseNumber = 4;
        script = new NationalVaccinationProgramScript();
        factory = IFactory(script.run());
        program = NationalVaccinationProgram(factory.deploy(admin, MaxdoseNumber, doseInterval, IncentiveAmt, tokenSetup[0], tokenSetup[1], tokenSetup[2], tokenSetup[3]));
        //program = new NationalVaccinationProgram(admin, MaxdoseNumber, doseInterval, IncentiveAmt, tokenSetup[0], tokenSetup[1], tokenSetup[2], tokenSetup[3]);
        certificate = new CertificateToken("NonTransferableCertificate","NTC");
        RegistrationOnSetup();
    }

    function RegistrationOnSetup() internal {
        vm.prank(admin);
        program.registerPatient(names, addr);
        vm.prank(user1);
        NationalVaccinationProgram.EnrolledPatient memory a = program.getMyProfile();
        assertTrue(a.Addr == user1);
    }

    function testexpectRevertfromNonadmin() public {
        vm.startPrank(makeAddr("hacker"));
        vm.expectRevert();
        program.registerPatient(names, addr);
        vm.stopPrank();
    }


    //soloTest on Cert
    function testCertContract() public {
        //certificateCount
        certificate.mintCertificate(user1); // mints to user1
        certificate.mintCertificate(user2); // mints to user2
        assertTrue(certificate.isCertified(user1) == true); // test user1 balance
        assertTrue(certificate.isCertified(user2) == true); // test user2 balance
        assertEq(certificate.certificateCount(), 2); // tests that the variable `certificateCount` is increasing with minting.
    }

    function testProgramCertificate() public {
        program.mintCertificate(user1); // mints to user1
        program.mintCertificate(user2); // mints to user2
        assertTrue(program.isCertified(user1) == true); // test user1 balance
        assertTrue(program.isCertified(user2) == true); // test user2 balance
        assertEq(program.certificateCount(), 2);
    }

    function testRegistration() public {
        string[] memory namesToRegister = new string[](2);
        address[] memory addrToRegister = new address[](2);
        namesToRegister[0] = "Henry MacDonald";
        namesToRegister[1] = "Antony Candy";
        addrToRegister[0] = user3;
        addrToRegister[1] = user4;
        vm.prank(admin);
        program.registerPatient(namesToRegister, addrToRegister);
        vm.prank(user3);
        NationalVaccinationProgram.EnrolledPatient memory a = program.getMyProfile();
        assertTrue(a.Addr == user3);
    }

    function testadministerVaccine() public {
        vm.startPrank(admin);
        bool done = program.administerVaccine(user1);
        changePrank(user1);
        NationalVaccinationProgram.EnrolledPatient memory a = program.getMyProfile();
        vm.stopPrank();
        assertEq(a.DoseCount, 1);
        assertTrue(done);
    }

    function testcertifyCompletedEnrollment() public {
        vm.startPrank(admin);
        bool done;
        for (uint256 i = 0; i < MaxdoseNumber; i++) {
            done = program.administerVaccine(user1);
            vm.warp(block.timestamp + doseInterval + 1);
        }
        changePrank(user1);
        NationalVaccinationProgram.EnrolledPatient memory a = program.getMyProfile();
        vm.stopPrank();
        assertEq(a.DoseCount, MaxdoseNumber);
        assertEq(program.balanceOf(user1), IncentiveAmt);
        assertTrue(done && a.Certified);
    }
}
