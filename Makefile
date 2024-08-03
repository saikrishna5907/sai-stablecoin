-include .env

.PHONY: all test test-zk clean deploy fund help install snapshot format anvil install deploy deploy-zk deploy-zk-sepolia deploy-sepolia verify

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install foundry-rs/forge-std@v1.9.1 --no-commit && forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit && smartcontractkit/chainlink-brownie-contracts@1.2.0 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

test-zk :; foundryup-zksync && forge test --zksync && foundryup

snapshot :; forge snapshot

coverage-report:; forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage

test-report:; make coverage-report -w

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

deploy:
	@forge script script/DeploySaiToken.s.sol:DeploySaiToken --rpc-url http://localhost:8545 --account local_anvil --broadcast