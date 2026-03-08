{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Util.ConversionSpec
Description : Unit tests for Type Conversion Utilities
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module Util.ConversionSpec (spec) where

import Test.Hspec
import Util.Conversion
import GraphQL.Types.Space
import GraphQL.Types.Common
import qualified MEDICUS.API as MA
import qualified MEDICUS.Space.Types as MS

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
            
            let total = lambda back + mu back + nu back
            total `shouldSatisfy` (\s -> abs (s - 1.0) < 1e-9)
    
    describe "Space Configuration Conversion" $ do
        it "converts basic space config to MEDICUS Engine format" $ do
            let config = SpaceConfigInput
                    { dimension = 3
                    , normWeights = NormWeightsInput 0.3 0.5 0.2
                    , constraints = []
                    }
            let medicus = toMEDICUSSpaceConfig config
            
            MA.scDimension medicus `shouldBe` 3
            MS.lambda (MA.scNormWeights medicus) `shouldBe` 0.3
            MS.mu (MA.scNormWeights medicus) `shouldBe` 0.5
            MS.nu (MA.scNormWeights medicus) `shouldBe` 0.2
        
        it "converts back from MEDICUS Engine format (partial)" $ do
            let medicus = MA.SpaceConfig
                    { MA.scDimension = 5
                    , MA.scBounds = replicate 5 (-1.0, 1.0)
                    , MA.scConstraints = []
                    , MA.scNormWeights = MS.NormWeights 0.4 0.4 0.2
                    , MA.scTolerance = 1e-6
                    }
            let back = fromMEDICUSSpaceConfig medicus
            
            dimension back `shouldBe` 5
            lambda (normWeights back) `shouldBe` 0.4
            mu (normWeights back) `shouldBe` 0.4
            nu (normWeights back) `shouldBe` 0.2
