{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Service.ValidationSpec
Description : Unit tests for Space Validation Service
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module Service.ValidationSpec (spec) where

import Test.Hspec
import Service.Validation
import GraphQL.Types.Space
import GraphQL.Types.Common
import GraphQL.Types.Error

spec :: Spec
spec = do
    describe "Validation Service" $ do
        describe "validateDimension" $ do
            it "accepts valid dimensions" $ do
                validateDimension 3 `shouldBe` []
                validateDimension 100 `shouldBe` []

            it "rejects negative or zero dimensions" $ do
                let errors = validateDimension 0
                length errors `shouldBe` 1
                errorCode (head errors) `shouldBe` InvalidDimension
                
                let errors' = validateDimension (-1)
                length errors' `shouldBe` 1

            it "rejects excessively large dimensions" $ do
                let errors = validateDimension 1001
                length errors `shouldBe` 1

        describe "validateNormWeights" $ do
            it "accepts valid norm weights (summing to 1.0)" $ do
                let weights = NormWeightsInput 0.4 0.3 0.3
                validateNormWeights weights `shouldBe` []

            it "rejects weights that don't sum to 1.0" $ do
                let weights = NormWeightsInput 0.5 0.5 0.5
                let errors = validateNormWeights weights
                length errors `shouldBe` 1
                errorCode (head errors) `shouldBe` InvalidNormWeights

            it "rejects negative weights" $ do
                let weights = NormWeightsInput 1.2 (-0.1) (-0.1)
                let errors = validateNormWeights weights
                length errors `shouldBe` 1

        describe "validateConstraints" $ do
            it "accepts valid constraints" $ do
                let constraints' = [ConstraintInput PrivacyProtection 0.8 (Just "High privacy")]
                validateConstraints constraints' `shouldBe` []

            it "rejects negative thresholds" $ do
                let constraints' = [ConstraintInput PrivacyProtection (-0.1) Nothing]
                let errors = validateConstraints constraints'
                length errors `shouldBe` 1
                field (head errors) `shouldBe` "constraints[0].threshold"

        describe "validateSpaceConfig" $ do
            it "validates a complete valid configuration" $ do
                let config = SpaceConfigInput 3 (NormWeightsInput 0.4 0.3 0.3) []
                let result = validateSpaceConfig config
                valid result `shouldBe` True
                errors result `shouldBe` []

            it "aggregates errors from multiple sources" $ do
                let config = SpaceConfigInput 0 (NormWeightsInput 0.5 0.5 0.5) []
                let result = validateSpaceConfig config
                valid result `shouldBe` False
                length (errors result) `shouldBe` 2

        describe "Precision Handling" $ do
            it "handles floating point precision for norm weights" $ do
                -- 0.1 + 0.2 + 0.7 = 1.0 (with slight floating point error)
                let weights = NormWeightsInput 0.1 0.2 0.7
                validateNormWeights weights `shouldBe` []
            
            it "rejects very small deviations from 1.0" $ do
                let weights = NormWeightsInput 0.33333333 0.33333333 0.33333333 -- sum 0.99999999
                let errors' = validateNormWeights weights
                length errors' `shouldBe` 1
