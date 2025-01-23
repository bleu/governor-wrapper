// VotingInterface.sol
pragma solidity ^0.8.20;

interface IAragonVoting {
    /**
     * @notice Assign a delegate who can vote on behalf of the sender
     * @param _delegate Address of the account to delegate to
     */
    function assignDelegate(address _delegate) external;

    /**
     * @notice Vote on behalf of another address that has delegated voting power
     * @param _voteId Vote identifier
     * @param _supports Whether the delegate supports the vote
     * @param _voter Address of the voter who delegated their power
     */
    function attemptVoteFor(
        uint256 _voteId,
        bool _supports,
        address _voter
    ) external;

    /**
     * @notice Get the state of a voter for a specific vote
     * @param _voteId Vote identifier
     * @param _voter Address of the voter
     * @return VoterState (Absent, Yea, or Nay)
     */
    function getVoterState(
        uint256 _voteId,
        address _voter
    ) external view returns (uint8);

    /**
     * @notice Check if an address can vote
     * @param _voteId Vote identifier
     * @param _voter Address of the voter
     * @return True if the voter can vote
     */
    function canVote(
        uint256 _voteId,
        address _voter
    ) external view returns (bool);

    /**
     * @notice Return the delegate address of the `_voter`
     * @param _voter Address of the voter
     */
    function getDelegate(address _voter) external view returns (address);

    /**
     * @notice Return the cumulative voting power of the `_voters` at the current block
     * @param _voters List of voters
     * @return balances Array of governance token balances
     */
    function getVotingPowerMultiple(
        address[] memory _voters
    ) external view returns (uint256[] memory balances);

    /**
     * @notice Create a new vote about "`_metadata`"
     * @dev  _executesIfDecided was deprecated to introduce a proper lock period between decision and execution.
     * @param _executionScript EVM script to be executed on approval
     * @param _metadata Vote metadata
     * @dev _castVote_deprecated Whether to also cast newly created vote - DEPRECATED
     * @dev _executesIfDecided_deprecated Whether to also immediately execute newly created vote if decided - DEPRECATED
     * @return voteId Id for newly created vote
     */
    function newVote(
        bytes memory _executionScript,
        string memory _metadata,
        bool /* _castVote_deprecated */,
        bool /* _executesIfDecided_deprecated */
    ) external returns (uint256 voteId);

    /**
     * @dev Return all information for a vote by its ID
     * @param _voteId Vote identifier
     * @return open True if the vote is open
     * @return executed Vote executed status
     * @return startDate Vote start date
     * @return snapshotBlock Vote snapshot block
     * @return supportRequired Vote support required
     * @return minAcceptQuorum Vote minimum acceptance quorum
     * @return yea Vote yeas amount
     * @return nay Vote nays amount
     * @return votingPower Vote power
     * @return script Vote script
     * @return phase Vote phase
     */
    function getVote(
        uint256 _voteId
    )
        external
        view
        returns (
            bool open,
            bool executed,
            uint64 startDate,
            uint64 snapshotBlock,
            uint64 supportRequired,
            uint64 minAcceptQuorum,
            uint256 yea,
            uint256 nay,
            uint256 votingPower,
            bytes memory script,
            uint8 phase
        );
}
