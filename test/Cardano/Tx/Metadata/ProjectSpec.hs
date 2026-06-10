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

        it "projects the worked treasury label-1694 schema" $
            assertGoldenFrom
                treasurySchemaDir
                "contingency-1694.input.ttl"
                "contingency-1694.ttl"

        it "emits a schema error instead of partial typed fields" $
            assertGoldenFrom
                treasurySchemaDir
                "missing-event.input.ttl"
                "missing-event.ttl"

        it "leaves labels without registered schemas unchanged" $
            assertGolden
                "schemas"
                "no-registered-label.input.ttl"
                "no-registered-label.ttl"

assertGolden :: FilePath -> FilePath -> FilePath -> IO ()
assertGolden schemaSubdir inputName expectedName = do
    assertGoldenFrom
        ("test/fixtures/metadata-typed" </> schemaSubdir)
        inputName
        expectedName

assertGoldenFrom :: FilePath -> FilePath -> FilePath -> IO ()
assertGoldenFrom schemaDir inputName expectedName = do
    schemas <- loadSchemasFrom schemaDir
    input <- readFixture inputName
    expected <- readFixture expectedName
    actual <- enrichMetadataTurtle schemas input
    actual `shouldBe` expected

treasurySchemaDir :: FilePath
treasurySchemaDir =
    "docs/case-studies/2026-05-amaru-treasury/schemas"

loadSchemas :: FilePath -> IO [MetadataSchema]
loadSchemas subdir =
    loadSchemasFrom ("test/fixtures/metadata-typed" </> subdir)

loadSchemasFrom :: FilePath -> IO [MetadataSchema]
loadSchemasFrom schemaDir = do
    result <-
        loadMetadataSchemaDirectory schemaDir
    case result of
        Right schemas -> pure schemas
        Left err -> do
            expectationFailure (renderMetadataSchemaParseError err)
            pure []

readFixture :: FilePath -> IO BS.ByteString
readFixture name =
    BS.readFile ("test/fixtures/metadata-typed" </> name)
