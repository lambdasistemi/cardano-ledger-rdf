{- |
Module      : Fixtures.TxGraph.S35_MetadataContingency1694
Description : Fixture 35 — the headline label-1694 metadata block (US3).
License     : Apache-2.0

Spec 062 / User Story 3 + FR-010: a faithful label-1694 rationale
block in the shape of the Amaru contingency-disburse transaction
@fe2eebc8…36aa4a@. It exercises every facet of the contract at
once — an integer label, nested maps, lists, maps-within-lists
(deep nesting), a chunked text value, and a flat hash string —
so the contract assertions C1–C4 are all golden-checked here:

* __C1__ — label @1694@ is an @xsd:integer@ (via
  @cardano:metadataLabel@), not a string.
* __C2__ — @body.event@ resolves to the text @"disburse"@ through
  ordinary @cardano:hasEntry@ / @cardano:metaKey@ /
  @cardano:metaValue@ predicates.
* __C3__ — @body.description@ is a two-element @cardano:MetaList@
  (a 64-byte chunk array), __not__ a single joined string
  (SC-002).
* __C4__ — @instance@ is a single @cardano:MetaText@ carrying the
  registry hash verbatim, the way the downstream registry-instance
  hygiene check reads it.

No label-specific interpretation is performed: this is the
generic substrate spec 063 consumes.
-}
module Fixtures.TxGraph.S35_MetadataContingency1694 (
    storyId,
    tx,
    shape,
) where

import Cardano.Ledger.Metadata (Metadatum (List, Map, S))
import Cardano.Tx.Build (output, setMetadata, spend)
import Cardano.Tx.Decode (ConwayTx)

import Fixtures.TxGraph.Helpers (
    ExpectedShape (..),
    StoryId (..),
    TxBuilder (..),
    baseShape,
    mkTx,
    stubTxIn,
    stubTxOut,
 )

-- | Story slug — kebab directory name under @test/fixtures/tx-graph/@.
storyId :: StoryId
storyId = StoryId "35-metadata-contingency-1694"

{- | Conway tx carrying a faithful CIP-1694-style contingency
disbursement rationale under metadata label 1694.
-}
tx :: ConwayTx
tx = mkTx . TxBuilder $ do
    _ <- spend (stubTxIn 35)
    _ <- output (stubTxOut 42_000_000)
    setMetadata 1694 rationale1694
    pure ()

-- | Expected structural shape.
shape :: ExpectedShape
shape = baseShape{esInputs = 1, esOutputs = 1}

-- | The label-1694 value tree.
rationale1694 :: Metadatum
rationale1694 =
    Map
        [ (S "body", body)
        , (S "instance", registryInstance)
        ]

-- | The rationale body map. Entry order is pinned by the golden.
body :: Metadatum
body =
    Map
        [ (S "event", S "disburse")
        , (S "label", S "Amaru contingency disbursement")
        , (S "references", references)
        , (S "description", description)
        , (S "destination", destination)
        , (S "justification", justification)
        , (S "context", context)
        ]

{- | A 2-element 64-byte chunk array (C3 / SC-002): the on-chain
shape for a >64-byte text value, preserved as a list.
-}
description :: Metadatum
description =
    List
        [ S "This contingency disbursement releases treasury funds per the ap"
        , S "proved rationale; see the references entry for full context."
        ]

{- | A list of reference maps — maps within a list within a map
(deep nesting).
-}
references :: Metadatum
references =
    List
        [ Map
            [ (S "label", S "Amaru treasury policy")
            , (S "uri", S "https://github.com/cardano-foundation/amaru")
            ]
        ]

-- | The disbursement destination.
destination :: Metadatum
destination =
    Map [(S "address", S "addr1qxckz…amaru-treasury-contingency")]

-- | A short justification list.
justification :: Metadatum
justification =
    List [S "Maintains treasury operations during the contingency window."]

-- | Document context.
context :: Metadatum
context =
    Map
        [ (S "@language", S "en")
        , (S "network", S "mainnet")
        ]

{- | The registry-instance hash as a single text leaf, read
verbatim by the downstream hygiene check (C4).
-}
registryInstance :: Metadatum
registryInstance =
    S "7d275cf8c09fd91e73879993ef13cb73915196478d5e3777992f9888"
