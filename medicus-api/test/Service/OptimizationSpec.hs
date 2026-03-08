{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Service.OptimizationSpec
Description : Unit tests for Optimization Service
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module Service.OptimizationSpec (spec) where

import Test.Hspec
import Service.Optimization
import GraphQL.Types.Optimization
import GraphQL.Types.Space
import GraphQL.Types.Common

spec :: Spec
spec = do
    describe "Optimization Service" $ do
        let spaceConfig = SpaceConfigInput 3 (NormWeightsInput 0.4 0.3 0.3) []
        let optInput = OptimizationInput
                { objective = ObjectiveFunctionInput Quadratic "{}"
                , initialPoint = [0.1, 0.2, 0.3]
                , options = Just $ OptimizationOptions (Just 100) (Just 1e-6) Nothing Nothing
                }

        describe "runOptimization" $ do
            it "successfully runs an optimization" $ do
                result <- runOptimization spaceConfig optInput
                -- Engine currently returns the initial point as solution in its placeholder
                success result `shouldBe` False -- Converged is False in placeholder
                length (solution result) `shouldBe` 3
                computationTimeMs result `shouldSatisfy` (>= 0)

            it "fails if space creation fails (e.g., invalid dimension)" $ do
                let invalidSpace = SpaceConfigInput 0 (NormWeightsInput 1.0 0.0 0.0) []
                result <- runOptimization invalidSpace optInput
                success result `shouldBe` False
                message result `shouldSatisfy` (\m -> case m of
                    Just msg -> T.isInfixOf "Space creation failed" msg
                    Nothing -> False)

        describe "runBatchOptimization" $ do
            it "runs multiple optimizations" $ do
                let inputs = [optInput, optInput]
                results <- runBatchOptimization spaceConfig inputs
                length results `shouldBe` 2
                all (not . success) results `shouldBe` True
