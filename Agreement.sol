// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Agreement {
    enum AgreementStatus { Created, Signed, Disputed }

    struct AgreementDetails {
        address[] actors;
        uint256 creationTimestamp;
        uint256 expirationTimestamp;
        AgreementStatus status;
    }

    mapping(uint256 => AgreementDetails) public agreements;
    mapping(address => uint256[]) public actorToAgreements; // Actor Address -> List of Agreement IDs
    mapping(uint256 => mapping(address => string)) public signatures; // Agreement ID -> Actor Address -> Signature Location
    uint256 public agreementCount = 0;

    event AgreementCreated(uint256 agreementId, address[] actors);
    event AgreementSigned(uint256 agreementId, address actor, string signatureLink);
    event AgreementDisputed(uint256 agreementId, address actor);
    event ActorAdded(uint256 agreementId, address actor);

    function createAgreement(address _actor, uint256 _expirationTimestamp) public {
        address[] memory actors = new address[](2);
        actors[0] = _actor;
        actors[1] = msg.sender;

        AgreementDetails memory newAgreement = AgreementDetails({
            actors: actors,
            creationTimestamp: block.timestamp,
            expirationTimestamp: _expirationTimestamp,
            status: AgreementStatus.Created
        });

        agreements[agreementCount] = newAgreement;
        actorToAgreements[_actor].push(agreementCount);
        actorToAgreements[msg.sender].push(agreementCount);
        emit AgreementCreated(agreementCount, actors);
        agreementCount++;
    }

    function signAgreement(uint256 _agreementId, string memory _signatureLink) public {
        require(_agreementId < agreementCount, "Invalid agreement ID");
        AgreementDetails storage agreement = agreements[_agreementId];

        bool isActor = false;
        for (uint256 i = 0; i < agreement.actors.length; i++) {
            if (agreement.actors[i] == msg.sender) {
                isActor = true;
                break;
            }
        }
        require(isActor, "Only actors can sign the agreement");

        signatures[_agreementId][msg.sender] = _signatureLink;
        agreement.status = AgreementStatus.Signed;
        emit AgreementSigned(_agreementId, msg.sender, _signatureLink);
    }

    function disputeAgreement(uint256 _agreementId) public {
        require(_agreementId < agreementCount, "Invalid agreement ID");
        AgreementDetails storage agreement = agreements[_agreementId];

        bool isActor = false;
        for (uint256 i = 0; i < agreement.actors.length; i++) {
            if (agreement.actors[i] == msg.sender) {
                isActor = true;
                break;
            }
        }
        require(isActor, "Only actors can dispute the agreement");

        agreement.status = AgreementStatus.Disputed;
        emit AgreementDisputed(_agreementId, msg.sender);
    }

    function addActor(uint256 _agreementId, address _actor) public {
        require(_agreementId < agreementCount, "Invalid agreement ID");
        AgreementDetails storage agreement = agreements[_agreementId];

        bool isExistingActor = false;
        for (uint256 i = 0; i < agreement.actors.length; i++) {
            if (agreement.actors[i] == msg.sender) {
                isExistingActor = true;
                break;
            }
        }
        require(isExistingActor, "Only existing actors can add new actors");

        agreement.actors.push(_actor);
        actorToAgreements[_actor].push(_agreementId);
        emit ActorAdded(_agreementId, _actor);
    }

    function getAgreementsForActor(address _actor) public view returns (uint256[] memory) {
        return actorToAgreements[_actor];
    }
}
