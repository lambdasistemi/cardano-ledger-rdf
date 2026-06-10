{- |
Module      : Cardano.Tx.Metadata.ProjectSpec
Description : Golden tests for schema-typed metadata projection.
License     : Apache-2.0
-}
module Cardano.Tx.Metadata.ProjectSpec (spec) where

import Data.ByteString qualified as BS
import System.FilePath ((</>))

import Cardano.Tx.Metadata.Project (enrichMetadataTurtle)
import Cardano.Tx.Metadata.Schema (
    MetadataSchema,
    loadMetadataSchemaDirectory,
    renderMetadataSchemaParseError,
 )

import Test.Hspec (
    Spec,
    describe,
    expectationFailure,
    it,
    shouldBe,
 )

spec :: Spec
spec =
    describe "Cardano.Tx.Metadata.Project" $ do
        it "projects scalar and nested map fields in schema order" $
            assertGolden
                "schemas"
                "us1-scalar-map.input.ttl"
                "us1-scalar-map.ttl"

        it "is idempotent for already-projected scalar metadata" $ do
            schemas <- loadSchemas "schemas"
            expected <- readFixture "us1-scalar-map.ttl"
            actual <- enrichMetadataTurtle schemas expected
            actual `shouldBe` expected

        it "joins chunked text and preserves the generic list tree" $
            assertGolden
                "schemas-us2"
                "us2-faithful.input.ttl"
                "us2-faithful.ttl"

assertGolden :: FilePath -> FilePath -> FilePath -> IO ()
assertGolden schemaSubdir inputName expectedName = do
    schemas <- loadSchemas schemaSubdir
    input <- readFixture inputName
    expected <- readFixture expectedName
    actual <- enrichMetadataTurtle schemas input
    actual `shouldBe` expected

loadSchemas :: FilePath -> IO [MetadataSchema]
loadSchemas subdir = do
    result <-
        loadMetadataSchemaDirectory
            ("test/fixtures/metadata-typed" </> subdir)
    case result of
        Right schemas -> pure schemas
        Left err -> do
            expectationFailure (renderMetadataSchemaParseError err)
            pure []

readFixture :: FilePath -> IO BS.ByteString
readFixture name =
    BS.readFile ("test/fixtures/metadata-typed" </> name)
