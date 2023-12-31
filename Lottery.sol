// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@chainlink/contracts/src/v0.7/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {
    address public manager;
    address payable[] public players;
    address payable[] public winners;
    uint public totalPrize;
    bytes32 public keyHash; // Declare keyHash as a public variable
    uint256 internal fee;
    address internal vrfCoordinator; // Declare vrfCoordinator variable
    uint256 public randomResult;
    bytes32 internal requestId;

    event RequestedRandomness(bytes32 indexed requestId);

    // Deployed Chainlink VRF Coordinator contract address
    address vrfCoordinatorAddress = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;

    // Deployed LINK token contract address
    address linkTokenAddress = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

    // Set the fee in LINK tokens
    uint256 public constant LINK_FEE = 1 * 10**18; // 1 LINK

    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        manager = msg.sender;
        keyHash = _keyHash; // Assign value to keyHash
        fee = _fee;
        vrfCoordinator = _vrfCoordinator; // Assign value to vrfCoordinator
    }

    function participate() public payable {
        require(msg.value == 1 ether, "Please pay 1 ether only");
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint) {
        require(manager == msg.sender, "You are not the manager");
        return address(this).balance;
    }

    function requestRandomNumber() internal returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens");
        requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);
        return requestId;
    }

    function fulfillRandomness(bytes32 _requestId, uint256 randomness) internal override {
        require(msg.sender == vrfCoordinator, "Fulfillment only allowed by Coordinator");
        require(requestId == _requestId, "Unexpected requestId");
        randomResult = randomness;
    }

    function pickWinners(uint numberOfWinners) public {
        require(manager == msg.sender, "You are not the manager");
        require(players.length >= numberOfWinners, "Not enough players for the specified number of winners");

        requestId = requestRandomNumber();

        uint256 r = randomResult;

        for (uint i = 0; i < numberOfWinners; i++) {
            uint index = r % players.length;
            winners.push(players[index]);
            players[index].transfer(totalPrize / numberOfWinners);
            players[index] = players[players.length - 1];
            players.pop();
        }
    }

    function getNumberOfWinners() public view returns (uint) {
        require(manager == msg.sender, "You are not the manager");
        return winners.length;
    }
}
