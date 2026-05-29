{- |
Module      : Cardano.Tx.View.CliTreeEntitySpec
Description : cli-tree entity resolution over IRI identifiers (#61).
License     : Apache-2.0

Regression coverage for the demo-blocking gap behind issue #61's
pipeline 2: with an operator overlay loaded (@tx-graph --rules@), the
@cli-tree@ view must render an output's address as the operator's
entity label (@amaru-treasury.network_compliance@) rather than the raw
@addr1…@ bech32.

The overlay links a @cardano:Entity@ to a body credential through
@cardano:hasIdentifier@. Since #57 those identifiers are
content-addressed @\<urn:cardano:id:…\>@ IRIs, not blank nodes, and
the cli-tree entity map only harvested blank-node identifiers — so the
label never resolved and @tx-view@ printed the raw address even with
@--rules@. This spec pins the IRI path through the public 'renderView'
surface.
-}
module Cardano.Tx.View.CliTreeEntitySpec (spec) where

import Data.ByteString (ByteString)
import Data.ByteString.Char8 qualified as BS8
import Data.List (isInfixOf)
import Test.Hspec (
    Spec,
    describe,
    expectationFailure,
    it,
    shouldSatisfy,
 )

import Cardano.Tx.View (ViewName (CliTree), renderView)

spec :: Spec
spec =
    describe "Cardano.Tx.View — cli-tree entity resolution (#61)" $ do
        it
            ( "resolves an output address to the operator entity label "
                <> "when the credential identifier is a urn: IRI"
            )
            $ withTree
            $ \tree -> do
                tree
                    `shouldSatisfy` ( "address: demo.named_scope"
                                        `isInfixOf`
                                    )

        it
            ( "still falls back to bech32 for an address with no "
                <> "matching entity"
            )
            $ withTree
            $ \tree ->
                tree `shouldSatisfy` ("address: addr1_unowned" `isInfixOf`)

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

withTree :: (String -> IO ()) -> IO ()
withTree k = case renderView CliTree jointGraph of
    Left err -> expectationFailure ("unexpected parse error: " <> show err)
    Right out -> k (BS8.unpack out)

{- | A minimal joint graph in the shape @tx-graph --rules CBOR@ emits:
a transaction with two outputs, an operator entity that claims one
output's payment credential through a urn: identifier IRI, and a
second output whose credential no entity claims.
-}
jointGraph :: ByteString
jointGraph =
    BS8.pack $
        unlines
            [ "@prefix cardano: <https://example.org/cardano#> ."
            , "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> ."
            , ""
            , ":named_scope a cardano:Entity ;"
            , "  rdfs:label \"demo.named_scope\" ;"
            , "  cardano:hasIdentifier <urn:cardano:id:PaymentKey:dead> ."
            , ""
            , ":tx a cardano:Transaction ;"
            , "  cardano:hasOutput _:out0 ;"
            , "  cardano:hasOutput _:out1 ."
            , ""
            , "_:out0 a cardano:TransactionOutput ;"
            , "  cardano:atAddress _:addr0 ;"
            , "  cardano:lovelace 1000000 ."
            , ""
            , "_:out1 a cardano:TransactionOutput ;"
            , "  cardano:atAddress _:addr1 ;"
            , "  cardano:lovelace 2000000 ."
            , ""
            , "_:addr0 a cardano:Address ;"
            , "  cardano:bech32 \"addr1_owned\" ;"
            , "  cardano:hasPaymentCredential _:pc0 ."
            , ""
            , "_:addr1 a cardano:Address ;"
            , "  cardano:bech32 \"addr1_unowned\" ;"
            , "  cardano:hasPaymentCredential _:pc1 ."
            , ""
            , "_:pc0 a cardano:PaymentCredential ;"
            , "  cardano:hasIdentifier <urn:cardano:id:PaymentKey:dead> ."
            , ""
            , "_:pc1 a cardano:PaymentCredential ;"
            , "  cardano:hasIdentifier <urn:cardano:id:PaymentKey:beef> ."
            ]
