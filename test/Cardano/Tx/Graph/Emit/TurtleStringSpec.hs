{- |
Module      : Cardano.Tx.Graph.Emit.TurtleStringSpec
Description : Turtle string-literal escaping invariants.
License     : Apache-2.0

Real governance anchors can contain control characters. Turtle quoted
string literals must escape those characters rather than writing raw
newlines into the graph.
-}
module Cardano.Tx.Graph.Emit.TurtleStringSpec (spec) where

import Data.ByteString.Char8 qualified as BS8

import Cardano.Tx.Graph.Emit (
    BodySection (..),
    EmitFormat (..),
    EmittedGraph (..),
    Object (..),
    Predicate (..),
    Subject (..),
    SubjectBlock (..),
    serialize,
 )

import Test.Hspec (Spec, describe, it, shouldSatisfy)

spec :: Spec
spec =
    describe "Cardano.Tx.Graph.Emit Turtle string literals" $
        it "escapes raw control characters in string literals" $ do
            let bytes =
                    serialize
                        Turtle
                        "turtle-string-spec"
                        EmittedGraph
                            { graphPrefixes = []
                            , graphOverlayTurtle = ""
                            , graphBody =
                                [ BodySection
                                    "Transaction body"
                                    [ SubjectBlock
                                        (SIri ":subject")
                                        [
                                            ( PIri
                                                "cardano:anchorUrl"
                                            , OStringLit
                                                "https://example.invalid/a\nb\tc\rd"
                                            )
                                        ]
                                    ]
                                ]
                            }
            bytes
                `shouldSatisfy` BS8.isInfixOf
                    "cardano:anchorUrl \"https://example.invalid/a\\nb\\tc\\rd\""
            bytes `shouldSatisfy` not . BS8.isInfixOf "a\nb"
