#!/bin/bash
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}*     Welcome to the Rainbow Protocol Setup      *${NC}"
echo -e "${CYAN}${BOLD}*              Powered by UGD Airdrop            *${NC}"
echo ""
echo -e "${YELLOW}${BOLD}This script is brought to you by UGD Airdrop!${NC}"
echo -e "${YELLOW}${BOLD}Join our community at t.me/ugdairdrop for more!${NC}"
echo ""

# Memeriksa apakah Docker sudah terinstal
if ! command -v docker &> /dev/null
then
    echo -e "${YELLOW}${BOLD}Docker is not installed. Installing Docker...${NC}"
    apt-get update
    apt-get install -y docker.io docker-compose
else
    echo -e "${CYAN}${BOLD}Docker is already installed. Skipping installation.${NC}"
fi

# Set default RPC credentials
RPC_URL="http://127.0.0.1:5000"
RPC_USER="demo"
RPC_PASSWORD="demo"

# User input for start height and wallet name
read -p "Enter Start Height (e.g., 42000): " START_HEIGHT
read -p "Enter Wallet Name: " WALLET_NAME

BITCOIN_CORE_REPO="https://github.com/mocacinno/btc_testnet4"
INDEXER_URL="https://github.com/rainbowprotocol-xyz/rbo_indexer_testnet/releases/download/v0.0.1-alpha/rbo_worker"
BITCOIN_CORE_DATA_DIR="/root/project/run_btc_testnet4/data"
DOCKER_COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

# Create directory for Bitcoin Core data
mkdir -p $BITCOIN_CORE_DATA_DIR

# Clone the Bitcoin Testnet repository
git clone $BITCOIN_CORE_REPO
cd btc_testnet4

git switch bci_node

# Remove any existing docker-compose.yml file
rm -f $DOCKER_COMPOSE_FILE

# Create a new docker-compose.yml file
cat <<EOF > $DOCKER_COMPOSE_FILE
version: '3'
services:
  bitcoind:
    image: mocacinno/btc_testnet4:bci_node
    privileged: true
    container_name: bitcoind
    volumes:
      - /root/project/run_btc_testnet4/data:/root/.bitcoin/
    command: ["bitcoind", "-testnet4", "-server", "-txindex", "-rpcuser=demo", "-rpcpassword=demo", "-rpcallowip=0.0.0.0/0", "-rpcbind=0.0.0.0:5000"]
    ports:
      - "8333:8333"
      - "48332:48332"
      - "5000:5000"
EOF

# Display the docker-compose.yml file
cat $DOCKER_COMPOSE_FILE

# Run Docker Compose to set up the bitcoind service
docker-compose up -d

# Allow time for bitcoind to start up
sleep 30

# Create a new Bitcoin wallet
docker exec -it bitcoind /bin/bash -c "bitcoin-cli -testnet4 -rpcuser=demo -rpcpassword=demo -rpcport=5000 createwallet $WALLET_NAME"
docker exec -it bitcoind /bin/bash -c "exit"

# Download and set up the Rainbow Protocol worker
wget $INDEXER_URL
chmod +x rbo_worker

# Create the environment file for the worker
echo "INDEXER_LOGGER_FILE=./logs/indexer" > $ENV_FILE

# Run the worker with the provided credentials and start height
./rbo_worker worker --rpc http://127.0.0.1:5000 --password demo --username demo --start_height $START_HEIGHT

# Final message to the user
echo "Setup completed. Make sure to check the JSON file and save your private key."
echo "For support, follow us at t.me/ugdairdrop!"
