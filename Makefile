-include .env

fmt :; forge fmt

build :; forge build

deploy anvil :; forge script script/DeployRaxCoin.s.sol:DeployRAX