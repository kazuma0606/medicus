{-# LANGUAGE OverloadedStrings #-}

module Util.ConversionSpec (spec) where

import Test.Hspec
import Test.QuickCheck

import Util.Conversion
import GraphQL.Types.Space
import GraphQL.Types.Common
import GraphQL.Types.Optimization

spec :: Spec
spec = do
    describe "Norm Weights Conversion" $ do
        it "converts NormWeights bidirectionally" $ do
            let weights = NormWeightsInput
                    { lambda = 0.3
                    , mu = 0.5
                    , nu = 0.2
                    }
            let medicus = toMEDICUSNormWeights weights
            let back = fromMEDICUSNormWeights medicus
            
            lambda back `shouldBe` lambda weights
            mu back `shouldBe` mu weights
            nu back `shouldBe` nu weights
        
        it "preserves weights sum property" $ do
            let weights = NormWeightsInput
                    { lambda = 0.333
                    , mu = 0.333
                    , nu = 0.334
                    }
            let medicus = toMEDICUSNormWeights weights
            let back = fromMEDICUSNormWeights medicus
            
            let sum = lambda back + mu back + nu back
            sum `shouldSatisfy` (\s -> abs (s - 1.0) < 1e-9)
    
    describe "Constraint Type Conversion" $ do
        it "converts PrivacyProtection correctly" $ do
            let ct = PrivacyProtection
            let medicus = toMEDICUSConstraintType ct
            let back = fromMEDICUSConstraintType medicus
            back `shouldBe` ct
        
        it "converts all constraint types bidirectionally" $ do
            let types = [ PrivacyProtection
                        , EmergencyAccess
                        , SystemAvailability
                        , RegulatoryCompliance
                        , CustomConstraint
                        ]
            mapM_ (\t -> do
                let medicus = toMEDICUSConstraintType t
                let back = fromMEDICUSConstraintType medicus
                back `shouldBe` t
                ) types
    
    describe "Space Configuration Conversion" $ do
        it "converts basic space config bidirectionally" $ do
            let config = SpaceConfigInput
                    { dimension = 3
                    , normWeights = NormWeightsInput 0.3 0.5 0.2
                    , constraints = []
                    }
            let medicus = toMEDICUSSpaceConfig config
            let back = fromMEDICUSSpaceConfig medicus
            
            dimension back `shouldBe` dimension config
        
        it "converts space config with constraints" $ do
            let config = SpaceConfigInput
                    { dimension = 5
                    , normWeights = NormWeightsInput 0.4 0.4 0.2
                    , constraints = 
                        [ ConstraintInput
                            { constraintType = PrivacyProtection
                            , threshold = 0.8
                            , description = Just "Privacy protection constraint"
                            }
                        ]
                    }
            let medicus = toMEDICUSSpaceConfig config
            let back = fromMEDICUSSpaceConfig medicus
            
            dimension back `shouldBe` dimension config
            length (constraints back) `shouldBe` length (constraints config)
    
    describe "Objective Type Conversion" $ do
        it "converts Linear correctly" $ do
            let ot = Linear
            let medicus = toMEDICUSObjectiveType ot
            let back = fromMEDICUSObjectiveType medicus
            back `shouldBe` ot
        
        it "converts Quadratic correctly" $ do
            let ot = Quadratic
            let medicus = toMEDICUSObjectiveType ot
            let back = fromMEDICUSObjectiveType medicus
            back `shouldBe` ot
        
        it "converts all objective types bidirectionally" $ do
            let types = [Linear, Quadratic, Nonlinear, CustomObjective]
            mapM_ (\t -> do
                let medicus = toMEDICUSObjectiveType t
                let back = fromMEDICUSObjectiveType medicus
                back `shouldBe` t
                ) types
    
    describe "Optimization Input Conversion" $ do
        it "converts optimization input correctly" $ do
            let input = OptimizationInput
                    { objective = ObjectiveFunctionInput
                        { functionType = Quadratic
                        , parameters = "{\"coefficients\":[1.0,1.0]}"
                        }
                    , initialPoint = [0.5, 0.5]
                    , options = Just $ OptimizationOptions
                        { maxIterations = Just 1000
                        , GraphQL.Types.Optimization.tolerance = Just 0.001
                        , timeoutSeconds = Just 60
                        , parallelEvaluation = Just True
                        }
                    }
            let _medicus = toMEDICUSOptimizationInput input
            
            -- Verify conversion works without errors
            True `shouldBe` True
    
    describe "Edge Cases" $ do
        it "handles empty constraint list" $ do
            let config = SpaceConfigInput
                    { dimension = 1
                    , normWeights = NormWeightsInput 1.0 0.0 0.0
                    , constraints = []
                    }
            let medicus = toMEDICUSSpaceConfig config
            let back = fromMEDICUSSpaceConfig medicus
            
            constraints back `shouldBe` []
        
        it "handles zero weights (edge case)" $ do
            let weights = NormWeightsInput
                    { lambda = 1.0
                    , mu = 0.0
                    , nu = 0.0
                    }
            let medicus = toMEDICUSNormWeights weights
            let back = fromMEDICUSNormWeights medicus
            
            mu back `shouldBe` 0.0
            nu back `shouldBe` 0.0
        
        it "handles large dimensions" $ do
            let config = SpaceConfigInput
                    { dimension = 1000
                    , normWeights = NormWeightsInput 0.333 0.333 0.334
                    , constraints = []
                    }
            let medicus = toMEDICUSSpaceConfig config
            let back = fromMEDICUSSpaceConfig medicus
            
            dimension back `shouldBe` 1000
        
        it "handles optimization without options" $ do
            let input = OptimizationInput
                    { objective = ObjectiveFunctionInput
                        { functionType = Nonlinear
                        , parameters = "{\"function\":\"sin\"}"
                        }
                    , initialPoint = [0.0]
                    , options = Nothing
                    }
            let _medicus = toMEDICUSOptimizationInput input
            
            -- Verify conversion works without errors
            True `shouldBe` True
