// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/hyperlane-monorepo/solidity/contracts/interfaces/IMailbox.sol";
import "../lib/hyperlane-monorepo/solidity/contracts/interfaces/IMessageRecipient.sol";

contract CounterBidirectional {
    uint256 public number;
    IMailbox public mailbox;

    event CounterTriggered(uint32 _destinationChainId, address _destinationAddress);
    event CounterIncremented(uint256 newNumber);

    constructor(address _mailbox) {
        mailbox = IMailbox(_mailbox);
    }

    // ------------------- SEND MESSAGE -------------------
    function sendMessage(
        uint32 _destinationChainId,
        address _destinationAddress,
        bytes calldata _body
    ) external returns (bytes32) {
        emit CounterTriggered(_destinationChainId, _destinationAddress);

        return mailbox.dispatch(
            _destinationChainId,
            addressToBytes32(_destinationAddress),
            _body
        );
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // ------------------- RECEIVE MESSAGE -------------------
    modifier onlyMailbox() {
        require(msg.sender == address(mailbox), "Not mailbox");
        _;
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external onlyMailbox {
        number++;

        emit CounterIncremented(number);
    }
}
