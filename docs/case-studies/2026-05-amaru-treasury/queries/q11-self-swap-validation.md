# Q11 - Self-swap validation: every placed order returns to the treasury

The operational reason to type the swap-order datum at all is to
**validate that proceeds come back to the treasury**. Sundae V3's
`OrderDatum` carries a `destination` field; if the operator places an
order whose destination is *not* their treasury, the post-swap USDM
lands somewhere they don't control. This query reads the typed
`destination.address.payment_credential` straight off every swap order
placed by a seed transaction and flags any whose recipient does not
match `amaru-treasury.network_compliance`'s script hash.

<div class="scrollbox" markdown>

```sparql
PREFIX cardano: <https://lambdasistemi.github.io/cardano-ledger-rdf/vocab/cardano#>
PREFIX rdfs:    <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ptx:     <https://lambdasistemi.github.io/cardano-rdf/fixtures/tx#>

SELECT DISTINCT
       (SUBSTR(?txid, 1, 12) AS ?seed) ?ix
       (SUBSTR(?destHex, 1, 12) AS ?dest_payment_cred_12)
       (IF (?destHex = ?ncHash, "yes", "NO") AS ?returns_to_treasury)
WHERE {
  # The 30 seed txids — first 30 lines of selections.txt.
  VALUES ?txid {
    "18d57a4f104df4cc776104ce626958e2110122392e4c4c7671edc8861b48452e"
    "affe90d1fa9a93b3e2a48009ef80634e9de8428640f5d673e85b002a86399982"
    "c150d5c5c67658c8f2a3bc24e16a4852257d46a03224257ac990fcca6f6fde78"
    "cb8f1a1254d650afc1c5b2a1e677df24ac72c4540e96eff52072bcb04b7274ba"
    "019586ee09f54155379d36ea2c6aa010296dcf5b8e28564a668bec1a44d8f503"
    "71ff129b5e0b5983ac01da968c6e345a8b6bc36d650a27f18c02ea9787a13dbe"
    "65bfd93936abf4fb26a135e89bd3ef133bb4b02152b37199586ed443979a95b1"
    "021e6b48610dd73b9c72c39f50986c1f2a34927fe7a764e0f06305f61b3b44ea"
    "013329ee0504d62c593491b76084bdd3958c0578037d28382c0de4611709c3f6"
    "107e439f247fad6bd05543d81b9139547c521f50e5409120bed9f3d80b644055"
    "10a5c1dafe7dd8d4ab680e35dc53b8b550da90bea55f2c758f36474064f2e598"
    "22e914892e83c22e19514937914ca32a0c059f9d1c5b555429edde0ea3406ae4"
    "2695f20941ac832a9b36fdbe4f0b78a8f5bafddf964b353b81aec360a13df3f3"
    "26ef34aa02aecfb068e44f00e7d2f50deef377d168a7e33d1e7d01a11f32d46d"
    "36d57c1be24bd617d1b7eb1f4aa4a391c3f351aa5b6cc4ac32ebc1dd2ded4d84"
    "488e5b417aa4f573528057fd1d7ab6de4f7ad06e296f945ee4097d8a94ee62e7"
    "5262be893119bd6d43c1c2fce5b0b89f7ac15f8e7d3d3dd66d0eb01e42b875d7"
    "59e10ca5e03b8d243c699fc45e1e18a2a825e2a09c5efa6954aec820a4d64dfe"
    "5fc04113da630ec676a5a7a66d82f53c0e64527ee592c3e6c5e1dccad67732ea"
    "7353059f0e0f59e974887b3f2405019e26c2a06673a9ce45d3cfdcbd814d5896"
    "7ac5f9e3f5de550b72aaf9e1c476bac02837e44d22600ddc00f63c7b4e753d7f"
    "a38cb99bab8eb9922454fc7ae61ca38ff31b54d0db4afa6b33933763ba1cfd09"
    "ad6ac0a1889733757f4503dac327ee57d3397dadf2948bff624f315ea0754aeb"
    "b5716ae98bb41b53c5fa2ebc6e8d5558879dc86d14fb998333e643095c6b233e"
    "b63aa2dd78c2a63b71aeba687cf45d445a98653a81f48774aa30236e47f30b86"
    "dfd355530e2d3baef6fc4cb22369c8b64aa117b0a84ff2cdaadc24cdc3fbc7bc"
    "f2791967f99ac04b33da17bd9c848b673c690a40d647b1e21e2651ff7a2f4657"
    "9f119393a85bb9aa0c94f8c649288dabb956b88dcbe055b10e741a2237123420"
    "a8bab7bfe1e2ed9d3a5b40189c8de51c5974a6e05c71fc1000a6abd57500b365"
    "4e2642080c8d171aad05baed11b076de498b76acecc1c2412660048fae8aefa3"
  }

  # network_compliance script hash (the 28 bytes baked into its bech32).
  BIND ("32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0d" AS ?ncHash)

  ?tx a cardano:Transaction ;
      cardano:hasTxId/cardano:bytesHex ?txid ;
      cardano:hasOutput ?out .
  ?out cardano:hasIndex ?ix ; cardano:hasDatum ?dat .
  ?dat ptx:OrderDatum_destination ?destination .
  ?destination ptx:_0_address ?address .
  ?address     ptx:_0_payment_credential ?pc .
  ?pc          ptx:_0_field0 ?pcid .
  ?pcid cardano:bytesHex ?destHex .
}
ORDER BY ?txid ?ix
```

</div>

Every row reads `"yes"`: every swap order the seed batch placed has
its `OrderDatum.destination.address.payment_credential` equal to the
treasury's script hash. The post-swap USDM is contractually required
to land back on `amaru-treasury.network_compliance`. No order leaks
to a third party.

The 28-byte hash `32201dc1e82708364c6c42a53f89f675314bb9ad5da2734aa10baa0d`
is the script hash bech32-encoded inside
`addr1xyezq8w...network_compliance`. Reading it from the typed
`OrderDatum` instead of inferring it post-scoop closes the loop: the
operator can validate the destination **before** signing a swap-order
placement, not retroactively from the scoop receipt.

**Why this query was not possible until limitation #5 was lifted**:
Sundae's upstream `plutus.json` declares the `order.spend` validator's
datum as `Data` (even though it ships a fully-typed
`types/order/OrderDatum` definition). Without the case-study's
one-`$ref` override at
[`blueprints/sundae-order-typed.cip57.json`](../blueprints/sundae-order-typed.cip57.json),
the destination stays as opaque CBOR bytes and the SPARQL above has
no `:OrderDatum_destination` predicate to join through.

Return to the [presentation](../case.md).
