// VotingInterface.sol
pragma solidity ^0.8.20;

interface IAragonVoting {
    enum VoterState {
        Absent, // Voter has not voted
        Yea, // Voter has voted for
        Nay, // Voter has voted against
        DelegateYea, // Delegate has voted for on behalf of the voter
        DelegateNay // Delegate has voted against on behalf of the voter
    }

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
    ) external view returns (VoterState);

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
}
