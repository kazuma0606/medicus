{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : GraphQL.SchemaSpec
Description : Integration tests for GraphQL Schema
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module GraphQL.SchemaSpec (spec) where

import Test.Hspec
import Data.Morpheus (interpreter)
import Data.Aeson (encode, object, (.=))
import qualified Data.ByteString.Lazy.Char8 as LBS

import GraphQL.Resolvers (rootResolver)

spec :: Spec
spec = do
    describe "GraphQL Schema" $ do
        it "responds to introspection query" $ do
            let introspectionQuery = "{ \"query\": \"{ __schema { types { name } } }\" }"
            response <- interpreter rootResolver (LBS.pack introspectionQuery)
            -- Basic check that we get a non-empty response with schema info
            LBS.unpack response `shouldContain` "__schema"
            LBS.unpack response `shouldContain` "Query"
            LBS.unpack response `shouldContain` "Mutation"

        it "contains MEDICUS specific types" $ do
            let introspectionQuery = "{ \"query\": \"{ __schema { types { name } } }\" }"
            response <- interpreter rootResolver (LBS.pack introspectionQuery)
            LBS.unpack response `shouldContain` "SpaceConfigInput"
            LBS.unpack response `shouldContain` "OptimizationResult"
            LBS.unpack response `shouldContain` "ConstraintType"
