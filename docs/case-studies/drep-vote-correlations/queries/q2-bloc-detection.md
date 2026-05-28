# Q2 - Bloc detection

Bloc detection uses the pairwise agreement matrix from Q1. A graph edge is
created when two DReps share at least 12 selected actions and agree on at
least 90% of them. Connected components over those edges yield **4 blocs**
with at least two DReps.

| Bloc | DReps | Epoch span | Verdict mix inside bloc observations |
| ---: | ---: | --- | --- |
| 1 | 142 | 576-632 | 1,999 Yes / 303 No / 109 Abstain |
| 2 | 3 | 576-632 | 29 Yes / 4 No / 17 Abstain |
| 3 | 2 | 576-632 | 20 Yes / 15 No |
| 4 | 2 | 576-632 | 30 Yes / 4 No / 5 Abstain |

The edge extract is the Q1 pairwise agreement query materialised without
`LIMIT`, then filtered to `common >= 12` and `agreementRate >= 0.90`. The
connected-component labelling is a small graph post-process over that edge
table.

Post-processing rule:

```text
edge(voter1, voter2) if common >= 12 and agreementRate >= 0.90
bloc = connected_component(edge)
```

Observed result: **4 connected components** with at least two DReps. The
largest bloc has **142** DReps and appears across the full selected proposal
epoch span, **576-632**.

Return to the [presentation](../case.md).
