// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// type declarations
// state variables
// events
// modifiers
// functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback (if exists)
// external
// public
// internal
// private
// view & pure

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @author  Juan Cardenas
 * @title   A sample raffle contract
 * @dev     Implements Chainlink VRF v2.5
 * @notice  This contract is a sample raffle contract
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle_SendMoreToEnterRaffle();

    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    // @dev The duration of the lottery in seconds
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint256 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    /* Events */
    event RaffleEntered(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        s_vrfCoordinator.requestRandomWords();
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle_SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        // 1. Makes migration easier
        // 2. Makes front-end "indexing" easier
        emit RaffleEntered(msg.sender);
    }

    // 1. Get a random number
    // 2 Use a random number to pick a player
    // 3. Be automatically called
    function pickWinner() external {
        // check to see if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {}

    /*
        Getter function
    */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
