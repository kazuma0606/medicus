{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : GraphQL.QuerySpec
Description : Integration tests for GraphQL Queries
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module GraphQL.QuerySpec (spec) where

import Test.Hspec
import Data.Morpheus (interpreter)
import qualified Data.ByteString.Lazy.Char8 as LBS

import GraphQL.Resolvers (rootResolver)

spec :: Spec
spec = do
    describe "GraphQL Queries" $ do
        describe "health" $ do
            it "returns healthy status" $ do
                let query = "{ \"query\": \"query { health { status version service } }\" }"
                response <- interpreter rootResolver (LBS.pack query)
                LBS.unpack response `shouldContain` "healthy"
                LBS.unpack response `shouldContain` "medicus-api"

        describe "listAvailableConstraints" $ do
            it "returns a list of constraint types" $ do
                let query = "{ \"query\": \"query { listAvailableConstraints }\" }"
                response <- interpreter rootResolver (LBS.pack query)
                LBS.unpack response `shouldContain` "PrivacyProtection"
                LBS.unpack response `shouldContain` "EmergencyAccess"

        describe "validateSpace" $ do
            it "validates a valid space configuration" $ do
                let query = "{ \"query\": \"query { validateSpace(config: { dimension: 3, normWeights: { lambda: 0.4, mu: 0.3, nu: 0.3 }, constraints: [] }) { valid errors { field errorMessage } } }\" }"
                response <- interpreter rootResolver (LBS.pack query)
                LBS.unpack response `shouldContain` "\"valid\":true"
                LBS.unpack response `shouldContain` "\"errors\":[]"

            it "returns validation errors for invalid configuration" $ do
                let query = "{ \"query\": \"query { validateSpace(config: { dimension: 0, normWeights: { lambda: 0.5, mu: 0.5, nu: 0.5 }, constraints: [] }) { valid errors { field errorCode } } }\" }"
                response <- interpreter rootResolver (LBS.pack query)
                LBS.unpack response `shouldContain` "\"valid\":false"
                LBS.unpack response `shouldContain` "InvalidDimension"
                LBS.unpack response `shouldContain` "InvalidNormWeights"
