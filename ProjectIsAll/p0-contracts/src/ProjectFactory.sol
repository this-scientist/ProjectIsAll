// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./ProjectEscrow.sol";

contract ProjectFactory {
    event ProjectCreated(
        uint256 indexed projectId,
        address indexed escrow,
        address indexed owner,
        uint256 goal
    );

    address[] public projects;
    mapping(uint256 => address) public projectAt;

    function createProject(
        address _token,
        uint256 _goal,
        uint256 _fundingDuration,
        uint16 _passBps,
        uint16 _quorumBps,
        uint256 _votingPeriod,
        uint256 _submitDeadlineDays,
        uint16 _bondBps,
        string calldata _metadataURI,
        bytes32[] calldata _milestoneDescs,
        uint16[] calldata _milestoneBps
    ) external returns (address) {
        ProjectEscrow escrow = new ProjectEscrow(
            _token,
            msg.sender,
            _goal,
            _fundingDuration,
            _passBps,
            _quorumBps,
            _votingPeriod,
            _submitDeadlineDays,
            _bondBps,
            _metadataURI,
            _milestoneDescs,
            _milestoneBps
        );

        uint256 projectId = projects.length;
        projects.push(address(escrow));
        projectAt[projectId] = address(escrow);

        emit ProjectCreated(projectId, address(escrow), msg.sender, _goal);
        return address(escrow);
    }

    function getProjectCount() external view returns (uint256) {
        return projects.length;
    }

    function getAllProjects() external view returns (address[] memory) {
        return projects;
    }
}
