{- |
Module      : Fixtures.TxGraph.S34_MetadataFaithful
Description : Fixture 34 — faithful, lossless metadata tree (US2).
License     : Apache-2.0

Spec 062 / User Story 2: the decoded tree mirrors the on-chain
metadatum without inventing or losing information.

* Label 10 is a two-element list ('Metadatum.List') — it must
  surface as a two-element @cardano:MetaList@, never joined
  (FR-003 / SC-002).
* Label 20 is a byte string ('Metadatum.B' → @cardano:MetaBytes@
  + @cardano:bytesHex@), distinguishable from a text leaf
  (FR-005): the bytes @0xdeadbeef@ render as the hex string
  @"deadbeef"@, not as UTF-8.
* Label 30 is a map ('Metadatum.Map') keyed by an integer and a
  byte string — non-string keys, preserved as full value nodes
  (FR-004).
-}
module Fixtures.TxGraph.S34_MetadataFaithful (
    storyId,
    tx,
    shape,
) where

import Data.ByteString.Char8 qualified as BS8

import Cardano.Ledger.Metadata (Metadatum (B, I, List, Map, S))
import Cardano.Tx.Build (output, setMetadata, spend)
import Cardano.Tx.Ledger (ConwayTx)

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
storyId = StoryId "34-metadata-faithful"

{- | Conway tx exercising list arity, a byte-string leaf, and a
non-string-keyed map.
-}
tx :: ConwayTx
tx = mkTx . TxBuilder $ do
    _ <- spend (stubTxIn 34)
    _ <- output (stubTxOut 42_000_000)
    setMetadata 10 (List [S "chunk-one", S "chunk-two"])
    setMetadata 20 (B (BS8.pack "\xde\xad\xbe\xef"))
    setMetadata
        30
        ( Map
            [ (I 1, S "by-int-key")
            , (B (BS8.pack "\xfe\xed\xfa\xce"), S "by-bytes-key")
            ]
        )
    pure ()

-- | Expected structural shape.
shape :: ExpectedShape
shape = baseShape{esInputs = 1, esOutputs = 1}
