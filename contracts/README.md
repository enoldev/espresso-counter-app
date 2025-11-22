# Counter Application

This is a sample application that showcases how to use Hyperlane to perform cross-chain message passing. Specifically, **this example uses Rari testnet and Appchain testnet** (along with the Hyperlane contract deploy on each chain). It also assumes a validator and a relayer running, and listening. The flow is the following:

1. The user triggers the “increment” of the counter on Rari (source chain).
2. Hyperlane relays the message to Appchain.
3. The counter is incremented on Appchain (destination chain).

In order for this to work, you will need a Hyperlane validator and relayer correctly configured to perform `Rari -> Appchain` message passing.

- **Rari Mailbox:** `0xb0bb23B185A7Ba519426C038DEcAFaB4D0a9055b`
- **Appchain Mailbox:** `0x4C58973d0Eb3CeB8aBfd933A1C6EE6f8EA178064`

**There are two different versions of the Counter application: `src/Counter.sol` and `src/CounterBidirectional.sol`.**

**NOTE:** In the examples belowm the Caldera RPCs are used. It is also possible to use the Espresso Caff Nodes for testing, but here we assume the Espresso integration happens on the Hyperlane infra.

## The Counter Application

The simplest version of the application, which hardcodes most of the configuration parameters. In this case, the communication only happens from Rari to Appchain (Rari -> Appchain).

### Before Your Begin

- Have Foundry and all its dependencies installed (you can use other frameworks like HardHat, but Foundry is used in the following examples)
- Have ETH on Rari testnet. This is necessary to initiate transactions on the source chain.
- Have ETH on Appchain testnet. This is necessary to deploy the smart contract.

### Understand the Flow

![](../docs/counterapp.png)

### Inspect the Code

- The `espresso-app` folder contains the Foundry project. The `src` is used to store the smart contract source code (in this case, `Counter.sol`). The `scripts` folder contains the logic to deploy the smart contract on the blockchain.
- Open the `src/Counter.sol` file and review the code logic. For simplicity, the smart contract contains the logic of both source and destination chain. The `sendMessage` function is used on the source chain (Rari) to trigger the counter. Then, Hyperlane calls the `handle` function on the destination chain (Appchain)

```solidity
contract Counter {
    uint256 public number;
    
    // 1.
    address constant mailboxAddress = 0xb0bb23B185A7Ba519426C038DEcAFaB4D0a9055b;
    // 2.
    address constant mailboxAddressDestination = 0x4C58973d0Eb3CeB8aBfd933A1C6EE6f8EA178064;

		// --------------- SOURCE: Logic for sending message ---------------
    function sendMessage(address appDestinationAddress) public returns (bytes32) {
        uint32 destinationChainId = 4661; // 3.

        IMailbox mailbox = IMailbox(mailboxAddress); // 4.
        bytes32 appDestinationAddressBytes32 = addressToBytes32(appDestinationAddress); // 5.
        bytes32 messageId = mailbox.dispatch(destinationChainId, appDestinationAddressBytes32, bytes("Hello, world")); // 6.

        return messageId;
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // --------------- DESTINATION: Logic for receiving a message ----------------------
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _body) external onlyMailbox { // 7.
        // Just increment the local counter when receiving the message
        number++;
    }
    
    modifier onlyMailbox() {
        require(msg.sender == mailboxAddressDestination);
        _;
    }
}
```
1. Hyperlane Mailbox address on the source chain (Rari). This is where the smart contract will send the message to trigger the counter.
2. Hyperlane Mailbox address on the destination chain (Appchain). This is where the message will get delivered.
3. Chain where the message will be delivered. 4661 corresponds to Appchain testnet.
4. In order to send a message to the source chain Hyperlane Mailbox, you import the Mailbox’s interface and initialize it with the actual smart contract address.
5. The address of the smart contract that will receive the message in the destination chain. In this example, the smart contract will be the Counter.sol contract deployed on the destination chain (because this contract is used for both sending and receiving messages).
6. Once you have the Mailbox initialized with the corresponding address, you execute the “dispatch” function with three parameters: the destination chain ID, the smart contract address and the message to deliver. In this example, the message is “Hello world” because you are only interested in triggering the function, not in the actual message.
7. The “handle” function is where Hyperlane will deliver the message in the destination chain. In this example, it increments the counter. The “onlyMailbox” modifier is used to ensure that only the Hyperlane Mailbox can execute the function.

### Deploy the Smart Contracts

1. In a command-line terminal, run the following `forge` command to deploy the smart contract on Rari:

```bash
forge script script/Counter.s.sol \
  --rpc-url https://rari-testnet.calderachain.xyz/ \
  --private-key <PRIVATE-KEY> \
  --broadcast \
  --chain-id 1918988905
```
Replace <PRIVATE-KEY> with the actual private key of the address that you will use to deploy the contract.
​

2. The logs will provide you with the smart contract address on Rari. You will use this address to interact with the contract.
Now, do the same to deploy on Appchain and save the resulting contract address.

```bash
forge script script/Counter.s.sol \
  --rpc-url https://appchaintestnet.rpc.caldera.xyz/http \
  --private-key <PRIVATE-KEY> \
  --broadcast \
  --chain-id 4661
```

### Test the Application

1. To trigger the counter, you execute the `sendMessage` function with the Appchain’s smart contract address as parameter:

```solidity
cast send <SMART-CONTRACT-ADDRESS-ON-RARI> \
  "sendMessage(address)" <SMART-CONTRACT-ADDRESS-ON-APPCHAIN> \
  --rpc-url https://rari-testnet.calderachain.xyz/http \
  --private-key <PRIVATE-KEY> --chain 1918988905
```

2. Now, Hyperlane will pick up the message and relay it to the destination chain. To verify the counter, call the `number()` function on the Appchain’s contract.

```bash
cast call <SMART-CONTRACT-ADDRESS-ON-APPCHAIN> "number()" \
  --rpc-url https://appchain.caff.testnet.espresso.network
```

## The CounterBidirectional Application

A modified version of the `Counter.sol` contract that can be used for bidirectional communication. The Hyperlane Mailbox is passed in the constructor, so it can be used to pass messages **from Rari to Appchain** and **from Appchain to Rari**.

### Deploy the Contracts

1. Deploy the contract on Rari:

```bash
MAILBOX=0xb0bb23B185A7Ba519426C038DEcAFaB4D0a9055b forge script script/CounterBidirectional.s.sol \
  --rpc-url https://rari-testnet.calderachain.xyz/http \
  --private-key <PRIVATE-KEY> \
  --broadcast \
  --chain-id 1918988905
```

You will get the smart contract address on Rari. Save this for later.

2. Deploy the contract on Appchain:

```bash
MAILBOX=0x4C58973d0Eb3CeB8aBfd933A1C6EE6f8EA178064 forge script script/CounterBidirectional.s.sol \
  --rpc-url https://appchaintestnet.rpc.caldera.xyz/http \
  --private-key <PRIVATE-KEY> \
  --broadcast \
  --chain-id 4661
```

You will get the smart contract address on Appchain. Save this for later.

### Test the application

#### Rari -> Appchain

1. Trigger the counter on Rari chain by calling the `sendMessage(...)` function with the Appchain's smart contract data:

```bash
cast send <SMART-CONTRACT-ADDRESS-ON-RARI> \
  "sendMessage(uint32,address,bytes)" 4661 <SMART-CONTRACT-ADDRESS-ON-APPCHAIN> 0x48656c6c6f20776f726c64 \
  --rpc-url https://rari-testnet.calderachain.xyz/http \
  --private-key $PRIVATE_KEY \
  --chain 1918988905
```

2. Now, the Hyperlane infra will pick up the message and deliver it to Appchain. To get the number of the counter:

```bash
cast call <SMART-CONTRACT-ADDRESS-ON-APPCHAIN> "number()" \
  --rpc-url https://appchaintestnet.rpc.caldera.xyz/http
```

#### Appchain -> Rari

1. Trigger the counter on Appchain by calling the `sendMessage(...)` function with the Rari's smart contract data:

```bash
cast send <SMART-CONTRACT-ADDRESS-ON-APPCHAIN> \
  "sendMessage(uint32,address,bytes)" 1918988905 <SMART-CONTRACT-ADDRESS-ON-RARI> 0x48656c6c6f20776f726c64 \
  --rpc-url https://appchaintestnet.rpc.caldera.xyz/http \
  --private-key $PRIVATE_KEY \
  --chain 4661
```

2. Now, the Hyperlane infra will pick up the message and deliver it to Rari. To get the number of the counter:

```bash
cast call <SMART-CONTRACT-ADDRESS-ON-RARI> "number()" \
  --rpc-url https://rari-testnet.calderachain.xyz/http
```