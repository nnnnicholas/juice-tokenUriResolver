# Onchain SVG Resolver

## Running tests

`forge test --fork-url $ETH_RPC_URL -v --via-ir --ffi --fork-block-number BLOCK_NUMBER --match-test Get`

Replace `$ETH_RPC_URL` and `BLOCK_NUMBER` with your preferred values.

## Deploying
### Goerli
#### DefaultTokenUriResolver
`forge create --rpc-url $GOERLI_RPC_URL --constructor-args-path deploy/DefaultTokenUriResolver/goerli_constructor_args --private-key $GOERLI_PRIV_KEY --etherscan-api-key $ETHERSCAN_API_KEY --via-ir --verify src/DefaultTokenUriResolver.sol:DefaultTokenUriResolver`

## Demo

![](src/tokenuriresolver.png)

useful byte length checker https://mothereff.in/byte-counter