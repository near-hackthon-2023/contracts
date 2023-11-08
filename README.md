## NearFi contracts

testnet:
- 0x8E3Af02d71Cd78316620eF234Cc9ea44aEc0BDBe

## Deployment

```bash
forge create --rpc-url https://testnet.aurora.dev  --constructor-args 0x901fb725c106E182614105335ad0E230c91B67C8 0xf4e9C0697c6B35fbDe5a17DB93196Afd7aDFe84f --private-key SECRET src/CoreFiCash.sol:CoreFiCash --legacy
```