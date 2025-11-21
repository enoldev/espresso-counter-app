This is a sample application that showcases how Espresso's finality helps in building fast and secure cross-chain applications. The flow is of the application is:

1. You trigger the Counter on the source chain (e.g., Rari Chain).
2. Hyperlane infrastructure relays the message to the destination chain (e.g., Apechain).
3. The Counter is incremented on the destination chain.

![](docs/counterapp.png)

In simple terms, you will need to deploy the Counter smart contract (in the `/contracts` folder) on both chain, and the Hyperlane infrastructure (Hyperlane contracts + nodes).

The real usage of Espresso comes at **Step 2**, when the Hyperlane node uses the Espresso Caff Node RPC (i.e., a full node's RPC that is instrumented to read from the Espresso Network) to **derive the blockchain state from the Espresso Network and ensure that the transaction on the source chain won't be reverted.**

# Tutorial

## Deploy Hyperlane

In order for the Counter to communicate between the two chains, you need to set up Hyperlane (contract + nodes).

1. Install the Hyperlane CLI.

1. Move to the `hyperlane` folder

1. Move the Hyperlane configuration to the `~/.hyperlane` folder in your computer. This is where Hyperlane CLI will look for chain configurations. In this case, you will the `source` chain (Rari) and `destination` chain (Apechain).

```bash
cp chains/source-metadata.yaml ~/.hyperlane/source/metadata.yaml
```

```bash
cp chains/destination-metadata.yaml ~/.hyperlane/destination/metadata.yaml
```

1. Generate the `core-config.yaml` file, which will contain the Hyperlane's validator and relayer addresses. This will be used when singing cross-chain messages:

```bash
hyperlane core init
```

**This will create `core-config.yaml` file in the `configs` folder. You can use the same file for both chains, just note that you will need ETH on the addresses specified on both chains.**

**NOTE:** You must include addresses that you have access to (i.e., you have the private keys).

1. Deploy the Hyperlane contracts on the source chain (Rari)

```bash
hyperlane core deploy --config config/core-config.yaml --chain source 
```

**NOTE:** You will be asked for the private key of the deployer address.
**NOTE1:** After the deployment, you will see the addresses of the different Hyperlane contracts. **Copy and save these addresses for later.**

2. Deploy the Hyperlane contracts on the destination chain (Apechain)

```bash
hyperlane core deploy --config config/core-config.yaml --chain destination 
```

**NOTE:** You will be asked for the private key of the deployer address.
**NOTE1:** After the deployment, you will see the addresses of the different Hyperlane contracts. **Copy and save these addresses for later.**

## Deploy Counter Contract

To deploy the contracts, you will need a funded wallet. Set an environment variable:

```bash
export PRIVATE_KEY=<YOUR_PRIVATE_KEY>
```

Move to the `contracts` folder of the project.

### On Rari

```bash
MAILBOX=<MAILBOX_ADDRESS> forge script script/CounterBidirectional.s.sol \
  --rpc-url https://rari-testnet.calderachain.xyz/http \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --chain-id 1918988905
```

**NOTE:** Replace `MAILBOX_ADDRESS` with the actual Hyperlane Mailbox address that you deployed previously (on Rari).

### On Apechain

```bash
MAILBOX=<MAILBOX_ADDRESS> forge script script/CounterBidirectional.s.sol \
  --rpc-url https://apechain-tnet.rpc.caldera.xyz/http \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --chain-id 3313939
```

**NOTE:** Replace `MAILBOX_ADDRESS` with the actual Hyperlane Mailbox address that you deployed previously (on Apechain).

## Deploy the Hyperlane Infrastructure

In order for messages to be delivered from the source chain to the destination chain, you need to set up a Hyperlane validator and relayer. For every message in the Hyperlane's source chain Mailbox, the validator signs the message with the provided private key. Then, the relayer picks it up and writes it into the destination chain Mailbox.

1. Update the `config-relayer.json` file with the required information:

- **Validator private key:** the private key of the addresses you set as validator in previous steps.
- **Mailbox address** (on both Rari and Apechain).
- **Validator Announce address** (on both Rari and Apechain).
- **Merkle Tree Hook address** (on both Rari and Apechain).

**NOTE:** Here is where Hyperlane will read from Espresso's finality through the Caff Node's RPC. As a fallback, you can also include Caldera's RPC, which reads finality from the sequencer.

2. Update the `config-validator-rari.json` file with the required information.

- **Validator private key:** the private key of the addresses you set as validator in previous steps.
- **Mailbox address** (on both Rari and Apechain).
- **Validator Announce address** (on both Rari and Apechain).
- **Merkle Tree Hook address** (on both Rari and Apechain).

**NOTE:** Here is where Hyperlane will read from Espresso's finality through the Caff Node's RPC. As a fallback, you can also include Caldera's RPC, which reads finality from the sequencer.

1. Start the Docker Compose services:

```bash
docker-compose up -d
```

**NOTE:** Check the status of the containers with `docker ps` and debug with `docker logs`.

## Interact with the Application

### From Rari to Apechain

1. Trigger the counter on Rari chain by calling the `sendMessage(...)` function with the Apechain's smart contract data:

```bash
cast send <SMART-CONTRACT-ADDRESS-ON-RARI> \
  "sendMessage(uint32,address,bytes)" 4661 <SMART-CONTRACT-ADDRESS-ON-APECHAIN> 0x48656c6c6f20776f726c64 \
  --rpc-url https://rari-testnet.calderachain.xyz/http \
  --private-key $PRIVATE_KEY \
  --chain 1918988905
```

2. Now, the Hyperlane infra will pick up the message and deliver it to Apechain. To get the number of the counter:

```bash
cast call <SMART-CONTRACT-ADDRESS-ON-APECHAIN> "number()" \
  --rpc-url https://apechain-tnet.rpc.caldera.xyz/http
```