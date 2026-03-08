{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Bench
Description : Performance benchmarks for MEDICUS API
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module Main (main) where

import Criterion.Main
import Control.DeepSeq (NFData, rnf)
import qualified Data.Vector.Storable as V
import qualified Data.Text as T

import GraphQL.Types.Optimization
import GraphQL.Types.Space
import GraphQL.Types.Common
import Service.Optimization
import Control.Monad.Logger (runNoLoggingT)

-- | Mock NFData instances for GraphQL types to use with Criterion
instance NFData OptimizationResult where
    rnf res = rnf (solution res) `seq` rnf (objectiveValue res) `seq` rnf (computationTimeMs res)

instance NFData ObjectiveType where
    rnf _ = ()

-- | Benchmark setup
setupOptimization :: Int -> (SpaceConfigInput, OptimizationInput)
setupOptimization dim = 
    let spaceConfig = SpaceConfigInput 
            { dimension = dim
            , normWeights = NormWeightsInput 0.4 0.3 0.3
            , constraints = []
            }
        optInput = OptimizationInput
            { objective = ObjectiveFunctionInput Quadratic "{}"
            , initialPoint = replicate dim 0.1
            , options = Just $ OptimizationOptions (Just 100) (Just 1e-6) Nothing Nothing
            }
    in (spaceConfig, optInput)

main :: IO ()
main = defaultMain
    [ bgroup "Optimization Service"
        [ bench "dimension 3" $ nfIO $ do
            let (sc, opt) = setupOptimization 3
            runNoLoggingT $ runOptimization sc opt
            
        , bench "dimension 10" $ nfIO $ do
            let (sc, opt) = setupOptimization 10
            runNoLoggingT $ runOptimization sc opt
            
        , bench "dimension 100" $ nfIO $ do
            let (sc, opt) = setupOptimization 100
            runNoLoggingT $ runOptimization sc opt
        ]
    , bgroup "Batch Processing"
        [ bench "batch size 5 (dim 3)" $ nfIO $ do
            let (sc, opt) = setupOptimization 3
            runNoLoggingT $ runBatchOptimization sc (replicate 5 opt)
        ]
    ]
