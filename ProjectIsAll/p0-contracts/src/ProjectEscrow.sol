// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../lib/oz/IERC20.sol";
import "../lib/oz/SafeERC20.sol";
import "../lib/oz/ReentrancyGuard.sol";

contract ProjectEscrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Status {
        Funding, // 0 众筹中
        Funded, // 1 已达标，等待接单
        InProgress, // 2 已接单，开发中
        Voting, // 3 里程碑投票中
        Completed, // 4 全部里程碑完成
        FundingFailed, // 5 众筹未达标：本金全额退款（池子 == totalRaised）
        Terminated // 6 中途终止：按出资比例退「剩余本金 + 没收保证金」
    }

    enum TerminationReason {
        MilestoneRejected, // 里程碑多次投票未通过
        DeveloperRevoked // 开发者超时被撤销
    }

    struct Milestone {
        bytes32 descriptionHash;
        uint16 releaseBps;
        bool released;
    }

    /// @notice 每个里程碑允许的最大提交次数（含首次）。用尽仍未通过则项目终止。
    uint8 public constant MAX_MILESTONE_ATTEMPTS = 2;

    event Contributed(address indexed backer, uint256 amount, uint256 totalRaised);
    event GoalReached(uint256 totalRaised);
    event FundingFailed();
    event JobAccepted(address indexed developer, bytes32 acceptanceHash, uint256 submitDeadline, uint256 bond);
    event MilestoneSubmitted(uint256 indexed milestoneIndex, bytes32 deliveryHash, uint8 attempt);
    event VoteCast(address indexed voter, uint256 indexed milestoneIndex, bool support, uint256 weight);
    event MilestoneReleased(uint256 indexed milestoneIndex, uint256 amount);
    event MilestoneRejected(uint256 indexed milestoneIndex, uint8 attempt, bool willResubmit);
    event DeveloperRevoked(address indexed developer);
    event ProjectTerminated(TerminationReason reason, uint256 refundPool);
    event BondReturned(address indexed developer, uint256 amount);
    event BondForfeited(uint256 amount);
    event Refunded(address indexed backer, uint256 amount);

    IERC20 public immutable token;
    address public immutable owner;
    uint256 public immutable goal;
    uint256 public immutable fundingDeadline;
    uint16 public immutable passBps;
    uint16 public immutable quorumBps;
    uint256 public immutable votingPeriod;
    uint256 public immutable submitDeadlineDays;
    /// @notice 开发者接单需缴纳的保证金，按 goal 的万分比计算（0 表示不需要保证金）。
    uint256 public immutable bondAmount;
    /// @notice 项目元数据指针（IPFS CID / data: URI / 其它存储方案），承载名称、描述、封面等链下信息。
    string public metadataURI;

    Milestone[] public milestones;
    uint256 public totalRaised;
    Status public status;
    uint8 public currentMilestone;
    uint256 public totalReleased;
    /// @notice 当前里程碑已提交并被否决的次数。
    uint8 public currentAttempts;

    address public developer;
    bytes32 public acceptanceHash;
    uint256 public submitDeadline;
    /// @notice 合约当前托管的开发者保证金（接单时转入，完成返还 / 终止没收）。
    uint256 public developerBond;
    /// @notice 终止时一次性结算的可退款总池（剩余本金 + 没收保证金），按出资比例分配。
    uint256 public terminationPool;

    mapping(address => uint256) public contributions;
    address[] public funders;
    mapping(address => bool) public hasFunded;

    mapping(address => uint256) public voteSnapshotWeights;
    uint256 public snapshotTotalWeight;
    uint256 public supportWeight;
    uint256 public opposeWeight;
    uint256 public voteDeadline;
    mapping(address => bool) public hasVoted;

    modifier onlyOwner() {
        require(msg.sender == owner, "Escrow: only owner");
        _;
    }

    modifier onlyDeveloper() {
        require(msg.sender == developer, "Escrow: only developer");
        _;
    }

    modifier inStatus(Status _status) {
        require(status == _status, "Escrow: wrong status");
        _;
    }

    constructor(
        address _token,
        address _owner,
        uint256 _goal,
        uint256 _fundingDuration,
        uint16 _passBps,
        uint16 _quorumBps,
        uint256 _votingPeriod,
        uint256 _submitDeadlineDays,
        uint16 _bondBps,
        string memory _metadataURI,
        bytes32[] memory _milestoneDescs,
        uint16[] memory _milestoneBps
    ) {
        require(_owner != address(0), "Escrow: zero owner");
        require(_goal > 0, "Escrow: goal must be > 0");
        require(_passBps > 0 && _passBps <= 10000, "Escrow: bad passBps");
        require(_quorumBps > 0 && _quorumBps <= 10000, "Escrow: bad quorumBps");
        require(_bondBps <= 10000, "Escrow: bad bondBps");
        require(_milestoneDescs.length > 0, "Escrow: no milestones");
        require(_milestoneDescs.length == _milestoneBps.length, "Escrow: milestone array mismatch");

        uint256 sum;
        for (uint256 i = 0; i < _milestoneBps.length; i++) {
            sum += _milestoneBps[i];
            milestones.push(
                Milestone({descriptionHash: _milestoneDescs[i], releaseBps: _milestoneBps[i], released: false})
            );
        }
        require(sum == 10000, "Escrow: bps sum must be 10000");

        token = IERC20(_token);
        owner = _owner;
        goal = _goal;
        fundingDeadline = block.timestamp + _fundingDuration;
        passBps = _passBps;
        quorumBps = _quorumBps;
        votingPeriod = _votingPeriod;
        submitDeadlineDays = _submitDeadlineDays;
        bondAmount = (_goal * _bondBps) / 10000;
        metadataURI = _metadataURI;
        status = Status.Funding;
    }

    // ── 众筹 ──────────────────────────────────────────────────────

    function contribute(uint256 _amount) external nonReentrant inStatus(Status.Funding) {
        require(block.timestamp < fundingDeadline, "Escrow: funding ended");
        require(_amount > 0, "Escrow: amount must be > 0");

        token.safeTransferFrom(msg.sender, address(this), _amount);
        contributions[msg.sender] += _amount;
        if (!hasFunded[msg.sender]) {
            hasFunded[msg.sender] = true;
            funders.push(msg.sender);
        }
        totalRaised += _amount;
        emit Contributed(msg.sender, _amount, totalRaised);

        if (totalRaised >= goal) {
            status = Status.Funded;
            emit GoalReached(totalRaised);
        }
    }

    function finalizeFunding() external inStatus(Status.Funding) {
        require(block.timestamp >= fundingDeadline, "Escrow: funding not ended");
        require(totalRaised < goal, "Escrow: goal reached, use contribute");

        status = Status.FundingFailed;
        emit FundingFailed();
    }

    // ── 退款（众筹失败 / 项目终止通用） ──────────────────────────────

    function refund() external nonReentrant {
        require(status == Status.FundingFailed || status == Status.Terminated, "Escrow: not refundable");
        uint256 contributed = contributions[msg.sender];
        require(contributed > 0, "Escrow: no contribution");

        contributions[msg.sender] = 0;
        uint256 amount = _refundShare(contributed);
        token.safeTransfer(msg.sender, amount);
        emit Refunded(msg.sender, amount);
    }

    function refundAll() external nonReentrant {
        require(status == Status.FundingFailed || status == Status.Terminated, "Escrow: not refundable");

        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            uint256 contributed = contributions[funder];
            if (contributed > 0) {
                contributions[funder] = 0;
                uint256 amount = _refundShare(contributed);
                if (amount > 0) {
                    token.safeTransfer(funder, amount);
                    emit Refunded(funder, amount);
                }
            }
        }
    }

    // ── 接单与里程碑 ────────────────────────────────────────────────

    function acceptJob(bytes32 _acceptanceHash) external nonReentrant inStatus(Status.Funded) {
        require(developer == address(0), "Escrow: already claimed");

        developer = msg.sender;
        acceptanceHash = _acceptanceHash;
        submitDeadline = block.timestamp + submitDeadlineDays * 1 days;
        status = Status.InProgress;

        if (bondAmount > 0) {
            developerBond = bondAmount;
            token.safeTransferFrom(msg.sender, address(this), bondAmount);
        }

        emit JobAccepted(msg.sender, _acceptanceHash, submitDeadline, bondAmount);
    }

    function submitMilestone(bytes32 _deliveryHash) external onlyDeveloper inStatus(Status.InProgress) {
        require(block.timestamp < submitDeadline, "Escrow: submit deadline passed");
        require(currentMilestone < milestones.length, "Escrow: all milestones done");

        status = Status.Voting;
        _snapshotVotes();
        voteDeadline = block.timestamp + votingPeriod;
        emit MilestoneSubmitted(currentMilestone, _deliveryHash, currentAttempts);
    }

    function vote(bool _support) external inStatus(Status.Voting) {
        require(block.timestamp < voteDeadline, "Escrow: voting ended");
        require(msg.sender != developer, "Escrow: dev cannot vote");
        require(!hasVoted[msg.sender], "Escrow: already voted");

        uint256 weight = voteSnapshotWeights[msg.sender];
        require(weight > 0, "Escrow: no voting weight");

        hasVoted[msg.sender] = true;
        if (_support) {
            supportWeight += weight;
        } else {
            opposeWeight += weight;
        }
        emit VoteCast(msg.sender, currentMilestone, _support, weight);
    }

    function finalizeMilestone() external nonReentrant inStatus(Status.Voting) {
        require(block.timestamp >= voteDeadline, "Escrow: voting not ended");

        uint256 votedWeight = supportWeight + opposeWeight;

        bool quorumMet = snapshotTotalWeight > 0 && (votedWeight * 10000 / snapshotTotalWeight) >= quorumBps;
        // votedWeight > 0 防止 quorumBps 配置为 0 时的除零。
        bool passed = quorumMet && votedWeight > 0 && (supportWeight * 10000 / votedWeight) >= passBps;

        if (passed) {
            uint256 index = currentMilestone;
            uint256 releaseAmount = totalRaised * milestones[index].releaseBps / 10000;

            milestones[index].released = true;
            totalReleased += releaseAmount;
            currentMilestone++;
            currentAttempts = 0;

            bool finished = currentMilestone >= milestones.length;
            status = finished ? Status.Completed : Status.InProgress;
            if (!finished) {
                // 进入下一里程碑，刷新提交期限。
                submitDeadline = block.timestamp + submitDeadlineDays * 1 days;
            }

            _resetVotingState();
            token.safeTransfer(developer, releaseAmount);
            emit MilestoneReleased(index, releaseAmount);

            if (finished) {
                _returnBond(); // 项目成功完成，返还保证金。
            }
        } else {
            currentAttempts++;
            bool willResubmit = currentAttempts < MAX_MILESTONE_ATTEMPTS;
            emit MilestoneRejected(currentMilestone, currentAttempts, willResubmit);

            _resetVotingState();
            if (willResubmit) {
                // 仍有重提机会：退回开发中，刷新提交期限，允许重新提交同一里程碑。
                status = Status.InProgress;
                submitDeadline = block.timestamp + submitDeadlineDays * 1 days;
            } else {
                // 用尽重提次数 → 终止并按比例退款（保证金没收给出资人）。
                _terminate(TerminationReason.MilestoneRejected);
            }
        }
    }

    function revokeDeveloper() external onlyOwner nonReentrant inStatus(Status.InProgress) {
        require(block.timestamp > submitDeadline, "Escrow: deadline not passed");

        emit DeveloperRevoked(developer);
        // 开发者超时未交付：终止项目，没收保证金补偿出资人。
        _terminate(TerminationReason.DeveloperRevoked);
    }

    // ── 视图 ──────────────────────────────────────────────────────

    function getMilestoneCount() external view returns (uint256) {
        return milestones.length;
    }

    function getFundersCount() external view returns (uint256) {
        return funders.length;
    }

    /// @notice 预览某出资人当前可退金额（基于当前状态与池子）。
    function refundableOf(address _backer) external view returns (uint256) {
        if (status != Status.FundingFailed && status != Status.Terminated) return 0;
        return _refundShare(contributions[_backer]);
    }

    // ── 内部逻辑 ───────────────────────────────────────────────────

    function _refundShare(uint256 _contributed) private view returns (uint256) {
        if (_contributed == 0) return 0;
        if (status == Status.FundingFailed) {
            // 池子恰为 totalRaised，全额退还本金。
            return _contributed;
        }
        // Terminated：按出资比例分配「剩余本金 + 没收保证金」组成的池子。
        return _contributed * terminationPool / totalRaised;
    }

    function _terminate(TerminationReason _reason) private {
        status = Status.Terminated;

        uint256 pool = totalRaised - totalReleased; // 尚未释放给开发者的本金余额。
        uint256 bond = developerBond;
        if (bond > 0) {
            developerBond = 0;
            pool += bond; // 没收的保证金并入退款池，补偿出资人。
            emit BondForfeited(bond);
        }
        terminationPool = pool;
        emit ProjectTerminated(_reason, pool);
    }

    function _returnBond() private {
        uint256 bond = developerBond;
        if (bond > 0) {
            developerBond = 0;
            token.safeTransfer(developer, bond);
            emit BondReturned(developer, bond);
        }
    }

    function _snapshotVotes() private {
        delete snapshotTotalWeight;
        delete supportWeight;
        delete opposeWeight;
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            delete hasVoted[funder];
            // 开发者若同时出资，其权重不计入投票，也不计入 quorum 分母，避免扭曲参与率。
            if (funder == developer) {
                voteSnapshotWeights[funder] = 0;
                continue;
            }
            uint256 amount = contributions[funder];
            voteSnapshotWeights[funder] = amount;
            snapshotTotalWeight += amount;
        }
    }

    function _resetVotingState() private {
        delete supportWeight;
        delete opposeWeight;
        delete voteDeadline;
        delete snapshotTotalWeight;
        for (uint256 i = 0; i < funders.length; i++) {
            delete voteSnapshotWeights[funders[i]];
            delete hasVoted[funders[i]];
        }
    }
}
