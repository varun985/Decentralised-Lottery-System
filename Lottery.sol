// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "@chainlink/contracts/src/v0.7/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {
    address public manager;
    address payable[] public players;
    address payable[] public winners;
    uint public totalPrize;
    bytes32 public keyHash;
    uint256 internal fee;
    address internal vrfCoordinator;

    event RequestedRandomness(bytes32 indexed requestId);

    uint256 public randomResult; // Declare randomResult variable

    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF coordinator address
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK token address
        )
    {
        manager = msg.sender;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311; // Replace with your specific key hash
        fee = 0.1 * 10**18; // Replace with your specific fee value
        vrfCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B; // Replace with your specific VRF coordinator address
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
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);
        return requestId;
    }

    function fulfillRandomness(bytes32 _requestId, uint256 randomness) internal override {
        require(msg.sender == vrfCoordinator, "Fulfillment only allowed by Coordinator");
        randomResult = randomness;
    }

    function pickWinners(uint numberOfWinners) public {
        require(manager == msg.sender, "You are not the manager");
        require(players.length >= numberOfWinners, "Not enough players for the specified number of winners");

        bytes32 requestId = requestRandomNumber();

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
