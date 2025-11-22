// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/hyperlane-monorepo/solidity/contracts/interfaces/IMailbox.sol";
import "../lib/hyperlane-monorepo/solidity/contracts/interfaces/IMessageRecipient.sol";

contract Counter {
    uint256 public number;

    // Rari testnet mailbox address
    address constant mailboxAddress = 0xb0bb23B185A7Ba519426C038DEcAFaB4D0a9055b;
    // Appchain testnet mailbox address
    address constant mailboxAddressDestination = 0x4C58973d0Eb3CeB8aBfd933A1C6EE6f8EA178064;

    // --------------- SOURCE: Logic for sending message ---------------
    function sendMessage(address appDestinationAddress) public returns (bytes32) {
        // Appchain ID
        uint32 destinationChainId = 4661;

        IMailbox mailbox = IMailbox(mailboxAddress);
        bytes32 appDestinationAddressBytes32 = addressToBytes32(appDestinationAddress);
        bytes32 messageId = mailbox.dispatch(destinationChainId, appDestinationAddressBytes32, bytes("Hello, world"));

        return messageId;
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // --------------- DESTINATION: Logic for receiving a message ----------------------
    modifier onlyMailbox() {
        require(msg.sender == mailboxAddressDestination);
        _;
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _body) external onlyMailbox {
        // Just increment the local counter when receiving the message
        number++;
    }
}
