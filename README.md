## NearFi contracts

testnet:
- 0x8E3Af02d71Cd78316620eF234Cc9ea44aEc0BDBe

## Deployment

```bash
forge create --rpc-url https://testnet.aurora.dev  --constructor-args 0x05b8777B6c280DB4E61CF0F63d59b4Ac8ec70538 0xf4e9C0697c6B35fbDe5a17DB93196Afd7aDFe84f --private-key SECRET src/CoreFiCash.sol:CoreFiCash --legacy
```