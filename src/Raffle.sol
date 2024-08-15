// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title A Raffle Contract Demo
 * @author Tshediso Matsasa
 * @notice This is a demo of a smart contract lottery
 * @dev Chainlink VRFv2 implemented
 */

contract Raffle is VRFConsumerBaseV2 {
    //////////////////// ERRORS ////////////////////

    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    //////////////////// TYPE DECLARATIONS ////////////////////

    enum RaffleState{OPEN, CALCULATING}

    //////////////////// STATE VARIABLES ////////////////////

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint32 private immutable i_callbackGasLimit;
    uint64 private immutable i_subscriptionID;
    uint256 private immutable i_entranceFee;
    // @dev duration of lottery in seconds
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    address payable [] private s_players;
    address private s_recentWinner;
    uint256 private s_lastTimeStamp;
    RaffleState private s_raffleState;

    //////////////////// EVENTS ////////////////////

    event RaffleEntered(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestID);

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 keyHash, uint64 subscriptionID, uint32 callbackGasLimit)VRFConsumerBaseV2(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionID = subscriptionID;
        i_callbackGasLimit =callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    //////////////////// EXTERNAL FUNCTIONS ////////////////////

    /**
     * @dev This function is the function used for potential players to enter the raffle.
     * 1. Potential players enter the raffle (If the raffle is in an open state).
     * 2. Successful entrants are pushed into s_players array.
     * 3. RaffleEntered event becomes emitted as a result.
     */
    function enterRaffle() external payable{
        if (msg.value < i_entranceFee) {revert Raffle__NotEnoughEthSent();}
        if (s_raffleState != RaffleState.OPEN) {revert Raffle__RaffleNotOpen();}

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Automation nodes call to perform an upkeep (Time for a winner to be picked).
     * 1. Upkeep is checked if it is needed.
     * 2. The raffle is in CALCULATING state.
     * 3. A requestID is generating from the relevant inputs need by the VRF Coordinator (Chainlink).
     * 4. A RequestedRaffleWinner event is emitted.
     */
    function performUpKeep(bytes calldata /*checkData*/) external{
        (bool upKeepNeeded,) = checkUpKeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

        uint256 requestID = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionID,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestID);
    }

    //////////////////// PUBLIC FUNCTIONS ////////////////////

    /**
     * @dev This is the function that the Chainlink Automation nodes call to see if it's time to perform an upkeep.
     * The following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The raffle is in OPEN state.
     * 3. The contract has ETH(aka, players).
     * 4. (Implicit) The subscription is funded with LINK.
     */
    function checkUpKeep(bytes memory /*checkData*/) public view returns(bool upKeepNeeded, bytes memory /*checkData*/){
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upKeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upKeepNeeded, "0x0");
    }

    //////////////////// INTERNAL FUNCTIONS ////////////////////

    /**
     * @dev This function is used to determine and pay the winner of the raffle in its active state.  
     * 1. The winner is determined by a randomized pick of the index in the s_players array
     * 2. The winner gets recorded through the emit PickedWinner event.
     * 3. Winner get the pool prize
     */
      function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {revert Raffle__TransferFailed();}
        
    }

    //////////////////// GETTER FUNCTIONS ////////////////////

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState){
        return s_raffleState;
    }

    function getPlayer(uint256 idxOfPlayer) external view returns (address){
        return s_players[idxOfPlayer];
    }

    function getRecentWinner() external view returns (address){
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns (uint256){
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256){
        return s_lastTimeStamp;
    }
}