# Repository Secrets

Agents must not populate repository secrets.

Run this from an operator shell with the token available in the environment:

```bash
gh secret set CACHIX_AUTH_TOKEN \
  --repo lambdasistemi/cardano-rdf \
  --body "$CACHIX_AUTH_TOKEN"
```

Verify with:

```bash
gh secret list --repo lambdasistemi/cardano-rdf
```
