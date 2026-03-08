{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Service.SpaceSpec
Description : Unit tests for Space Service
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module Service.SpaceSpec (spec) where

import Test.Hspec
import Service.Space
import GraphQL.Types.Space
import GraphQL.Types.Common

spec :: Spec
spec = do
    describe "Space Service" $ do
        describe "createSpace" $ do
            it "successfully creates a space with valid configuration" $ do
                let config = SpaceConfigInput 3 (NormWeightsInput 0.4 0.3 0.3) []
                result <- createSpace config
                success result `shouldBe` True
                spaceId result `shouldNotBe` ""

            it "fails to create a space with invalid configuration" $ do
                let config = SpaceConfigInput 0 (NormWeightsInput 0.4 0.3 0.3) []
                result <- createSpace config
                success result `shouldBe` False
                message result `shouldBe` Just "Validation failed"

        describe "validateSpace" $ do
            it "validates configuration through the service" $ do
                let config = SpaceConfigInput 3 (NormWeightsInput 0.4 0.3 0.3) []
                result <- validateSpace config
                valid result `shouldBe` True

                let invalidConfig = SpaceConfigInput 0 (NormWeightsInput 0.4 0.3 0.3) []
                invalidResult <- validateSpace invalidConfig
                valid invalidResult `shouldBe` False

        describe "getSpaceInfo" $ do
            it "returns space information for a given ID" $ do
                result <- getSpaceInfo "temp-id"
                result `shouldNotBe` Nothing
                let Just info = result
                infoSpaceId info `shouldBe` "temp-space-id"
                infoDimension info `shouldBe` 3
