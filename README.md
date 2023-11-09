## NearFi contracts

testnet:
- 0x83C3c43A434749c227f47b03be7E5568fEA63632

## Deployment

```bash
forge create --rpc-url https://testnet.aurora.dev  --constructor-args 0x901fb725c106E182614105335ad0E230c91B67C8 0xf4e9C0697c6B35fbDe5a17DB93196Afd7aDFe84f --private-key SECRET src/CoreFiCash.sol:CoreFiCash --legacy
```