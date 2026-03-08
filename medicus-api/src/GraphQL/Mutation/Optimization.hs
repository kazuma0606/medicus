{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : GraphQL.Mutation.Optimization
Description : GraphQL mutation resolvers for Optimization operations
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module GraphQL.Mutation.Optimization
    ( resolveOptimize
    , resolveOptimizeBatch
    ) where

import Control.Monad.IO.Class (MonadIO)

import GraphQL.Schema (OptimizeArgs(..), OptimizeBatchArgs(..))
import GraphQL.Types.Optimization (OptimizationResult, BatchOptimizationInput(..))
import GraphQL.Types.Space (SpaceConfigInput(..))
import GraphQL.Types.Common (NormWeightsInput(..))
import Service.Optimization (runOptimization, runBatchOptimization)

-- | Resolver for optimize mutation
resolveOptimize :: MonadIO m => OptimizeArgs -> m OptimizationResult
resolveOptimize args = do
    -- Note: In a real system, we'd fetch the space config from a database
    -- For this MVP, we use a default space config based on the initial point dimension
    let dim = length (initialPoint (input (args :: OptimizeArgs) :: OptimizationInput))
    let defaultSpaceConfig = SpaceConfigInput
            { dimension = dim
            , normWeights = NormWeightsInput 0.4 0.3 0.3
            , constraints = []
            }
    runOptimization defaultSpaceConfig (input args)

-- | Resolver for optimizeBatch mutation
resolveOptimizeBatch :: MonadIO m => OptimizeBatchArgs -> m [OptimizationResult]
resolveOptimizeBatch args = do
    let inputs' = inputs (batchInput args :: BatchOptimizationInput)
    let dim = if null inputs' then 1 else length (initialPoint (head inputs' :: OptimizationInput))
    let defaultSpaceConfig = SpaceConfigInput
            { dimension = dim
            , normWeights = NormWeightsInput 0.4 0.3 0.3
            , constraints = []
            }
    runBatchOptimization defaultSpaceConfig inputs'
