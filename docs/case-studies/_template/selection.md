# Dataset selection

Explain how the transaction set was selected. Include the seed identifiers,
the Koios endpoints or equivalent API calls used to expand them, and the
rule that turns those responses into the txids listed in `selections.txt`.

```sh
curl -sS "https://api.koios.rest/api/v1/proposal_list?limit=200&order=block_time.desc"
curl -sS -G "https://api.koios.rest/api/v1/vote_list" \
  --data-urlencode "proposal_id=eq.gov_action1..."
```

End with a short count table that reconciles the selected transaction
classes to the total lattice size.
