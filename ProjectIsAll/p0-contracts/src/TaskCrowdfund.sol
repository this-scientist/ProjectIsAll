// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PlatformToken.sol";
import "./MultisigVerifier.sol";

/// @title TaskCrowdfund — on-chain task lifecycle & crowdfunding engine
/// @notice Manages the full lifecycle of a task:
///         Publish → Crowdfund → Active → InProgress → Review → Settled
///
///         Funds are held in this contract until multisig settlement.
///         Tasks can be cancelled during crowdfunding (refund backers)
///         or re-listed if the review fails.
contract TaskCrowdfund {
    // ════════════════════════════════════════════════════════════════
    //  Type definitions
    // ════════════════════════════════════════════════════════════════

    enum Status {
        CROWDFUNDING,   // Accepting contributions; no developer assigned
        ACTIVE,         // Funding goal reached; open for claims
        IN_PROGRESS,    // Developer claimed; working on delivery
        UNDER_REVIEW,   // Deliverable submitted; multisig voting in progress
        COMPLETED,      // Multisig approved; bounty paid to developer
        CANCELLED,      // Either funding failed or task was cancelled
        REJECTED        // Multisig rejected deliverable; task will be re-listed
    }

    struct Task {
        uint256 id;
        address publisher;          // Who created the task
        string metadataURI;         // IPFS / off-chain link to description
        uint256 bounty;             // Total PIA tokens for the winner (in wei)
        uint256 goal;               // Crowdfunding target in PIA (in wei)
        uint256 deadline;           // Timestamp when crowdfunding ends
        uint256 submitDeadline;     // Timestamp developer must submit by
        uint256 totalRaised;        // Sum of all contributions so far
        address developer;          // Address that claimed the task
        Status status;
        mapping(address => uint256) contributions; // funder → amount
        address[] funders;          // List to iterate when refunding
    }

    // ════════════════════════════════════════════════════════════════
    //  Events
    // ════════════════════════════════════════════════════════════════

    event TaskPublished(uint256 indexed taskId, address indexed publisher, uint256 bounty, uint256 goal);
    event ContributionMade(uint256 indexed taskId, address indexed funder, uint256 amount);
    event GoalReached(uint256 indexed taskId, uint256 totalRaised);
    event TaskClaimed(uint256 indexed taskId, address indexed developer);
    event DeliverableSubmitted(uint256 indexed taskId, address indexed developer);
    event TaskApproved(uint256 indexed taskId, uint256 bountyPaid);
    event TaskRejected(uint256 indexed taskId);
    event TaskCancelled(uint256 indexed taskId);
    event RefundIssued(uint256 indexed taskId, address indexed funder, uint256 amount);
    event TaskReListed(uint256 indexed taskId, uint256 newTaskId);

    // ════════════════════════════════════════════════════════════════
    //  State variables
    // ════════════════════════════════════════════════════════════════

    PlatformToken public immutable token;
    MultisigVerifier public immutable multisig;

    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;

    // ════════════════════════════════════════════════════════════════
    //  Constructor — I provide this
    // ════════════════════════════════════════════════════════════════

    constructor(address _token, address _multisig) {
        require(_token != address(0), "TaskCrowdfund: zero token address");
        require(_multisig != address(0), "TaskCrowdfund: zero multisig address");
        token = PlatformToken(_token);
        multisig = MultisigVerifier(_multisig);
    }


    // ════════════════════════════════════════════════════════════════
    //  MODIFIER — you fill this
    // ════════════════════════════════════════════════════════════════

    /// === FILL IN: onlyStatus modifier ===
    /// @notice Restrict a function to a specific task status.
    /// @param _taskId  Task to check
    /// @param _status  Required status
    ///
    /// Requirements:
    ///   Revert with `"TaskCrowdfund: invalid status"` if tasks[_taskId].status != _status.
    ///
    /// === YOUR CODE BELOW (~3 lines) ===
    // modifier onlyStatus(uint256 _taskId, Status _status) { ... }


    // ════════════════════════════════════════════════════════════════
    //  publishTask() — you fill this
    // ════════════════════════════════════════════════════════════════

    /// === FILL IN: publishTask ===
    /// @notice Create a new task and enter CROWDFUNDING.
    /// @param _metadataURI   Off-chain description link (IPFS, Arweave, etc.)
    /// @param _bounty        Total PIA reward for completion
    /// @param _goal          Crowdfunding target in PIA (wei)
    /// @param _durationDays  Number of days the crowdfunding will last
    ///
    /// Requirements:
    ///   1. _goal > 0 (must have a funding target)
    ///   2. _bounty > 0 (must have a reward)
    ///   3. Publisher must approve this contract to spend _bounty PIA tokens
    ///      before calling.  Then call token.transferFrom(publisher, address(this), _bounty).
    ///   4. Increment taskCount and assign id.
    ///   5. Store all fields in tasks[id], status = CROWDFUNDING.
    ///   6. Set deadline = block.timestamp + (_durationDays * 1 days).
    ///   7. Emit TaskPublished.
    ///
    /// === YOUR CODE BELOW (~15 lines) ===
    // function publishTask(
    //     string calldata _metadataURI,
    //     uint256 _bounty,
    //     uint256 _goal,
    //     uint256 _durationDays
    // ) external returns (uint256 taskId) { ... }


    // ════════════════════════════════════════════════════════════════
    //  contribute() — you fill this
    // ════════════════════════════════════════════════════════════════

    /// === FILL IN: contribute ===
    /// @notice Add funds to a crowdfunding task.
    /// @param _taskId  Target task
    /// @param _amount  PIA tokens to contribute (wei)
    ///
    /// Requirements:
    ///   1. Task status must be CROWDFUNDING.
    ///   2. block.timestamp < tasks[_taskId].deadline.
    ///   3. _amount > 0.
    ///   4. Transfer _amount PIA from msg.sender to this contract via token.transferFrom.
    ///      (Caller must approve first.)
    ///   5. Update totalRaised and store contribution in mapping.
    ///   6. Push msg.sender to funders[] if first contribution from this address.
    ///   7. Emit ContributionMade.
    ///   8. If totalRaised >= goal after this contribution:
    ///      - Set status to ACTIVE
    ///      - Emit GoalReached
    ///
    /// === YOUR CODE BELOW (~20 lines) ===
    // function contribute(uint256 _taskId, uint256 _amount) external { ... }


    // ════════════════════════════════════════════════════════════════
    //  claimTask() — you fill this
    // ════════════════════════════════════════════════════════════════

    /// === FILL IN: claimTask ===
    /// @notice Developer claims an ACTIVE task.
    /// @param _taskId  Task to claim
    ///
    /// Requirements:
    ///   1. Task status must be ACTIVE.
    ///   2. msg.sender must NOT be the task publisher.
    ///   3. Set developer = msg.sender.
    ///   4. Set status to IN_PROGRESS.
    ///   5. Set submitDeadline = block.timestamp + 14 days (example window).
    ///   6. Emit TaskClaimed.
    ///
    /// === YOUR CODE BELOW (~8 lines) ===
    // function claimTask(uint256 _taskId) external { ... }


    // ════════════════════════════════════════════════════════════════
    //  submitForReview() — you fill this
    // ════════════════════════════════════════════════════════════════

    /// === FILL IN: submitForReview ===
    /// @notice Developer submits deliverable for multisig review.
    /// @param _taskId  Task being submitted
    ///
    /// Requirements:
    ///   1. Task status must be IN_PROGRESS.
    ///   2. Only the assigned developer can call.
    ///   3. block.timestamp < submitDeadline.
    ///   4. Change status to UNDER_REVIEW.
    ///   5. Emit DeliverableSubmitted.
    ///
    /// === YOUR CODE BELOW (~6 lines) ===
    // function submitForReview(uint256 _taskId) external { ... }


    // ════════════════════════════════════════════════════════════════
    //  approveTask() — you fill this (called by multisig after 3/5)
    // ════════════════════════════════════════════════════════════════

    /// === FILL IN: approveTask ===
    /// @notice Multisig-approved: pay developer and close task.
    /// @param _taskId  Task to finalize
    ///
    /// Requirements:
    ///   1. Task status must be UNDER_REVIEW.
    ///   2. Only the MultisigVerifier contract can call this.
    ///   3. Transfer bounty (tasks[_taskId].bounty) to developer via token.transfer.
    ///   4. Change status to COMPLETED.
    ///   5. Emit TaskApproved.
    ///
    /// === YOUR CODE BELOW (~6 lines) ===
    // function approveTask(uint256 _taskId) external { ... }


    // ════════════════════════════════════════════════════════════════
    //  rejectTask() — you fill this (called by multisig after 3/5)
    // ════════════════════════════════════════════════════════════════

    /// === FILL IN: rejectTask ===
    /// @notice Multisig rejected the deliverable. Mark REJECTED so
    ///         the task can be re-listed (via reListTask).
    /// @param _taskId  Rejected task
    ///
    /// Requirements:
    ///   1. Task status must be UNDER_REVIEW.
    ///   2. Only the MultisigVerifier contract can call this.
    ///   3. Change status to REJECTED.
    ///   4. Emit TaskRejected.
    ///
    /// === YOUR CODE BELOW (~4 lines) ===
    // function rejectTask(uint256 _taskId) external { ... }


    // ════════════════════════════════════════════════════════════════
    //  reListTask() — you fill this
    // ════════════════════════════════════════════════════════════════

    /// === FILL IN: reListTask ===
    /// @notice Re-list a REJECTED task so a new developer can claim it.
    /// @param _taskId  The rejected task
    ///
    /// Requirements:
    ///   1. Task status must be REJECTED.
    ///   2. Only the original publisher can call.
    ///   3. Reset developer to address(0), status back to ACTIVE.
    ///   4. submitDeadline is extended by another 14 days.
    ///   5. Emit TaskReListed.
    ///
    /// === YOUR CODE BELOW (~6 lines) ===
    // function reListTask(uint256 _taskId) external { ... }


    // ════════════════════════════════════════════════════════════════
    //  cancelTask() — you fill this
    // ════════════════════════════════════════════════════════════════

    /// === FILL IN: cancelTask ===
    /// @notice Cancel a task that hasn't reached its goal before deadline.
    ///         Can be called by anyone after the crowdfunding deadline
    ///         if goal wasn't met.
    /// @param _taskId  Task to cancel
    ///
    /// Requirements:
    ///   1. Task status must be CROWDFUNDING.
    ///   2. block.timestamp >= deadline.
    ///   3. totalRaised < goal (only cancel if goal not met).
    ///   4. Mark status CANCELLED.
    ///   5. Emit TaskCancelled.
    ///   6. Call _refundAll(_taskId) to return funds.
    ///
    /// === YOUR CODE BELOW (~6 lines) ===
    // function cancelTask(uint256 _taskId) external { ... }


    // ════════════════════════════════════════════════════════════════
    //  refund() — you fill this
    // ════════════════════════════════════════════════════════════════

    /// === FILL IN: refund ===
    /// @notice Allow a single funder to withdraw their contribution
    ///         from a CANCELLED task.
    /// @param _taskId  Cancelled task
    ///
    /// Requirements:
    ///   1. Task status must be CANCELLED.
    ///   2. msg.sender must have contributed > 0.
    ///   3. Transfer contribution back to msg.sender.
    ///   4. Reset contribution to 0.
    ///   5. Emit RefundIssued.
    ///
    /// === YOUR CODE BELOW (~8 lines) ===
    // function refund(uint256 _taskId) external { ... }


    // ════════════════════════════════════════════════════════════════
    //  Private helpers — I provide the skeleton, you fill logic
    // ════════════════════════════════════════════════════════════════

    /// === FILL IN: _refundAll ===
    /// @notice Iterate over all funders of a task and return their contributions.
    ///
    /// Requirements:
    ///   For each address in tasks[_taskId].funders:
    ///     1. Read the contribution amount.
    ///     2. If > 0, transfer it back via token.transfer.
    ///     3. Reset contribution to 0.
    ///   This is NOT a public function; it should be internal.
    ///
    /// === YOUR CODE BELOW (~8 lines) ===
    // function _refundAll(uint256 _taskId) internal { ... }
}

