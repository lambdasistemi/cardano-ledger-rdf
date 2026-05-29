{- |
Module      : Cardano.Tx.View.TurtleSpec
Description : Reader coverage for the [] anonymous-bnode shorthand (#61).
License     : Apache-2.0

Regression coverage for issue #61 bug 2: the in-repo Turtle reader
behind 'Cardano.Tx.View.renderView' must accept the W3C Turtle §2.6
blank-node-property-list forms — @[] predicateObjectList .@ and the
inline @[ predicateObjectList ] .@ — because the rules overlay emitter
writes off-chain attestations as @[] a cardano:Attestation ; … .@.
Before the fix the reader rejected the leading @[@ with
@malformed Turtle graph: unexpected character: [@, which broke
@tx-graph --rules … | tx-view@.

The reader is a hidden library module, so the regression is exercised
through the public 'renderView' surface — the same entry point
@tx-view@ uses — rather than by importing the parser directly.
-}
module Cardano.Tx.View.TurtleSpec (spec) where

import Data.ByteString (ByteString)
import Data.ByteString.Char8 qualified as BS8
import Test.Hspec (
    Spec,
    describe,
    expectationFailure,
    it,
    shouldSatisfy,
 )

import Cardano.Tx.View (
    ViewName (CliTree),
    renderView,
 )

spec :: Spec
spec =
    describe
        ( "Cardano.Tx.View — [] blank-node-property-list reader "
            <> "(#61 bug 2)"
        )
        $ do
            it
                ( "accepts the [] a cardano:Attestation ; … . block the "
                    <> "overlay emitter produces"
                )
                $ shouldParse attestationTtl

            it
                ( "accepts two [] blocks in one document (distinct "
                    <> "anonymous subjects, no collision)"
                )
                $ shouldParse twoAttestationsTtl

            it "accepts the inline [ predicateObjectList ] . form" $
                shouldParse inlineBracketTtl

            it
                ( "still rejects a stray ] with no opening bracket "
                    <> "(the reader did not turn permissive)"
                )
                $ renderView CliTree strayCloseTtl `shouldSatisfy` isLeft

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

-- | Assert the canonical-Turtle reader accepts the input (no parse error).
shouldParse :: ByteString -> IO ()
shouldParse ttl = case renderView CliTree ttl of
    Right _ -> pure ()
    Left err ->
        expectationFailure
            ("expected a clean parse, got: " <> show err)

isLeft :: Either a b -> Bool
isLeft = either (const True) (const False)

----------------------------------------------------------------------
-- Fixtures
----------------------------------------------------------------------

prefixes :: [String]
prefixes =
    [ "@prefix cardano: <https://example.org/cardano#> ."
    , "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> ."
    ]

mkTtl :: [String] -> ByteString
mkTtl body = BS8.pack (unlines (prefixes <> body))

attestationTtl :: ByteString
attestationTtl =
    mkTtl
        [ "[] a cardano:Attestation ;"
        , "  rdfs:label \"Invoice INV-635\" ;"
        , "  cardano:attests :amaru.antithesis ;"
        , "  cardano:ipfs <ipfs://bafyfoo> ."
        ]

twoAttestationsTtl :: ByteString
twoAttestationsTtl =
    mkTtl
        [ "[] a cardano:Attestation ;"
        , "  rdfs:label \"first\" ."
        , ""
        , "[] a cardano:Attestation ;"
        , "  rdfs:label \"second\" ."
        ]

inlineBracketTtl :: ByteString
inlineBracketTtl =
    mkTtl ["[ a cardano:Attestation ; rdfs:label \"x\" ] ."]

strayCloseTtl :: ByteString
strayCloseTtl = mkTtl ["] a cardano:Attestation ."]
