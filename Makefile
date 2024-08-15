-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil huff

DEFAULT_ANVIL_KEY :=  0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

all:  remove install build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std --no-commit && forge install smartcontractkit/chainlink --no-commit && forge install transmissions11/solmate --no-commit

# Update Dependencies
update:; forge update

build:; forge build

compile:; forge compile

test :; @forge test --fork-url $(SEPOLIA_RPC_URL) 

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1