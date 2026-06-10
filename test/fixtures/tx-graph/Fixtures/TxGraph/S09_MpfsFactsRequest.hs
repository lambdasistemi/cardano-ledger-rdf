{- |
Module      : Fixtures.TxGraph.S09_MpfsFactsRequest
Description : Conway tx builder for fixture 09-mpfs-facts-request (044 Story 9).
License     : Apache-2.0

An operator submits a facts-request transaction to the MPFS oracle. The tx
places ten copies of the same @Fact@ datum (one per oracle output) at the
oracle script address; each output carries an inline datum of the same shape
with per-output variable slots for the fact's content. A single change
output returns to the operator wallet. The 044 narrative drives the
rendering — the tx-graph emitter decodes the inline datum via the
@mpfs-fact.cip57.json@ blueprint into a typed AST
with a named @requester@ field.

The harness contract this slice exercises is purely structural: 1 input
(operator's UTxO), 11 outputs (10 oracle facts + 1 operator change), all
other body fields zero. @assertShape@ does not inspect output addresses,
datums, or the blueprint decode — those rendering distinctions are
exercised by the rules-overlay emit path against @rules.yaml@, not here.
The per-output coin values on the fact outputs are illustrative
stubs; @assertShape@ only counts.

The transaction body is composed via the @Cardano.Tx.Build@ DSL.
'replicateM_' chains ten 'output' calls to build the 10 oracle-fact
outputs in sequence; a final 'output' adds the operator change. The
DSL's underlying 'Send' instruction appends to the body @outputs@
sequence with no deduplication, so the ten identical 'stubTxOut'
values produce ten distinct sequence positions.
-}
module Fixtures.TxGraph.S09_MpfsFactsRequest (
    storyId,
    tx,
    shape,
) where

import Control.Monad (replicateM_)

import Fixtures.TxGraph.Helpers (
    ExpectedShape (..),
    StoryId (..),
    TxBuilder (..),
    baseShape,
    mkTx,
    stubTxIn,
    stubTxOut,
 )

import Cardano.Tx.Build (output, spend)
import Cardano.Tx.Decode (ConwayTx)

-- | Story slug — kebab directory name under @test/fixtures/tx-graph/@.
storyId :: StoryId
storyId = StoryId "09-mpfs-facts-request"

{- | Conway tx body: 1 operator input, 10 oracle-fact outputs (each a
1.5 ADA stub) plus 1 operator change output (19.825 ADA).
-}
tx :: ConwayTx
tx = mkTx . TxBuilder $ do
    _ <- spend (stubTxIn 1)
    replicateM_ 10 (output (stubTxOut 1_500_000))
    _ <- output (stubTxOut 19_825_000)
    pure ()

-- | Expected structural shape per 044 Story 9.
shape :: ExpectedShape
shape = baseShape{esInputs = 1, esOutputs = 11}
