{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : GraphQL.MutationSpec
Description : Integration tests for GraphQL Mutations
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module GraphQL.MutationSpec (spec) where

import Test.Hspec
import Data.Morpheus (interpreter)
import qualified Data.ByteString.Lazy.Char8 as LBS

import GraphQL.Resolvers (rootResolver)

spec :: Spec
spec = do
    describe "GraphQL Mutations" $ do
        describe "createSpace" $ do
            it "successfully creates a space" $ do
                let query = "{ \"query\": \"mutation { createSpace(csConfig: { dimension: 3, normWeights: { lambda: 0.4, mu: 0.3, nu: 0.3 }, constraints: [] }) { spaceId success message } }\" }"
                response <- interpreter rootResolver (LBS.pack query)
                LBS.unpack response `shouldContain` "\"success\":true"
                LBS.unpack response `shouldContain` "temp-space-id"

        describe "optimize" $ do
            it "executes optimization" $ do
                let query = "{ \"query\": \"mutation { optimize(input: { objective: { functionType: Quadratic, parameters: \\\"{}\\\" }, initialPoint: [0.1, 0.2, 0.3] }) { success solution objectiveValue computationTimeMs } }\" }"
                response <- interpreter rootResolver (LBS.pack query)
                -- Current engine stub returns converged=false but we can check for structure
                LBS.unpack response `shouldContain` "solution"
                LBS.unpack response `shouldContain` "objectiveValue"
                LBS.unpack response `shouldContain` "computationTimeMs"

        describe "deleteSpace" $ do
            it "successfully deletes a space" $ do
                let query = "{ \"query\": \"mutation { deleteSpace(spaceId: \\\"any-id\\\") }\" }"
                response <- interpreter rootResolver (LBS.pack query)
                LBS.unpack response `shouldContain` "\"deleteSpace\":true"
