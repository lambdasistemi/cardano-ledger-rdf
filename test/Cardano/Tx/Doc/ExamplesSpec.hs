{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Cardano.Tx.Doc.ExamplesSpec
Description : Regression coverage for the Haddock @>>>@ examples shipped
              by the public library.

Every @>>>@ block in the library's Haddock comments is mirrored as an
hspec expectation here. This is the in-tree replacement for a full
@doctest@ harness — wiring @doctest@ proper would require either
adding it to @cabal-haskell-packages@ or breaking the Conway-era
@time@ pin (the Hackage @doctest@ executable depends on @ghc@, which
in turn pulls a newer @time@). The expectation pattern keeps the
examples honest: any drift between the Haddock comment and the
library's actual behaviour fails this spec.

When a new @>>>@ example is added to a Haddock comment in
@src\/Cardano\/**\/*.hs@, add a matching expectation below.
-}
module Cardano.Tx.Doc.ExamplesSpec (spec) where

import Data.Either (isRight)
import Test.Hspec

import Cardano.Tx.Blueprint (
    blueprintPreamble,
    parseBlueprintJSON,
    preambleTitle,
 )
import Cardano.Tx.Decode (decodeBech32Address)
import Cardano.Tx.Graph.Emit.Blueprint (blueprintFieldPredicate)
import Cardano.Tx.Graph.Rules.Load (parseRulesYamlText)

spec :: Spec
spec = describe "Haddock examples (doctest-equivalent)" $ do
    describe "Cardano.Tx.Decode.decodeBech32Address" $ do
        it "decodes the fixture-02 alice address (Right)" $
            isRight
                ( decodeBech32Address
                    "addr1qx9aqvsf6gne2640jec828s25gzhk5wp2day8u24kf8mrs2v0zyuvk80fay35dx008p45ts0u6cdrv9g2maetq8jm8psznjcrz"
                )
                `shouldBe` True
        it "rejects a malformed bech32 input with the framing reason" $
            decodeBech32Address "not-an-address"
                `shouldBe` Left
                    "bech32 decode failed: StringToDecodeMissingSeparatorChar"

    describe "Cardano.Tx.Graph.Rules.Load.parseRulesYamlText" $ do
        it "parses a single-entity rules.yaml blob (alice)" $
            fmap
                length
                ( parseRulesYamlText
                    "entities:\n\
                    \  - name: alice\n\
                    \    from-address: addr1qx9aqvsf6gne2640jec828s25gzhk5wp2day8u24kf8mrs2v0zyuvk80fay35dx008p45ts0u6cdrv9g2maetq8jm8psznjcrz\n"
                )
                `shouldBe` Right 1
        it "returns the empty entity list for an empty document" $
            parseRulesYamlText "" `shouldBe` Right []

    describe "Cardano.Tx.Blueprint.parseBlueprintJSON" $ do
        it "lifts the preamble title from a minimal blueprint" $ do
            let blob =
                    "{\"preamble\":{\"title\":\"demo\",\
                    \\"plutusVersion\":\"v3\"},\
                    \\"validators\":[{\"title\":\"spend\",\
                    \\"datum\":{\"schema\":{\"dataType\":\"integer\"}}}]}"
            fmap (preambleTitle . blueprintPreamble) (parseBlueprintJSON blob)
                `shouldBe` Right "demo"
        it "surfaces the aeson diagnostic via Left on malformed JSON" $
            case parseBlueprintJSON "not json" of
                Left e -> take 10 e `shouldBe` "Unexpected"
                Right _ -> expectationFailure "parser accepted invalid JSON"

    describe "Cardano.Tx.Graph.Emit.Blueprint.blueprintFieldPredicate" $ do
        it "mints the constructor_field-shaped IRI for a named field" $
            show (blueprintFieldPredicate "SwapOrder" "recipient")
                `shouldBe` "PIri \":SwapOrder_recipient\""
        it "passes through caller-resolved fallback strings" $
            show (blueprintFieldPredicate "_0" "field0")
                `shouldBe` "PIri \":_0_field0\""
