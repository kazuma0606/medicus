{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Service.Optimization
Description : Service for MEDICUS optimization operations
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com

This module provides service-level functions for running optimizations
on MEDICUS spaces.
-}

module Service.Optimization
    ( -- * Optimization Operations
      runOptimization
    , runBatchOptimization
    ) where

import Data.Text (Text)
import qualified Data.Text as T
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Logger (MonadLogger, logInfoN)
import Data.Time.Clock (getCurrentTime, diffUTCTime)

-- GraphQL Types
import GraphQL.Types.Optimization
    ( OptimizationInput(..)
    , OptimizationResult(..)
    , ObjectiveFunctionInput(..)
    )
import GraphQL.Types.Space
    ( SpaceConfigInput(..)
    )

-- MEDICUS Engine integration
import qualified MEDICUS.API as MA
import qualified MEDICUS.Space.Types as MS
import Util.Conversion (toMEDICUSSpaceConfig, toMEDICUSOptimizationConfig, fromAPIOptimizationResult)

-- | Run a single optimization process
runOptimization :: (MonadIO m, MonadLogger m) => SpaceConfigInput -> OptimizationInput -> m OptimizationResult
runOptimization spaceInput optInput = do
    start <- liftIO getCurrentTime
    logInfoN "Optimization started"
    
    -- 1. Prepare engine types
    let spaceConfig = toMEDICUSSpaceConfig spaceInput
    let optConfig = toMEDICUSOptimizationConfig optInput
    
    -- 2. Create space and objective function
    case MA.createSpace spaceConfig of
        Left err -> do
            let msg = T.pack $ "Space creation failed: " ++ show err
            logInfoN msg
            return $ errorResult msg
        Right space -> do
            -- Create a default objective function
            let objective = MS.MedicusFunction
                    { MS.mfFunction = \_ -> 0.0
                    , MS.mfGradient = \_ -> mempty
                    , MS.mfHessian = \_ -> mempty
                    , MS.mfConstraints = []
                    }
            
            -- 3. Execute optimization
            let result = MA.optimize space objective optConfig
            
            end <- liftIO getCurrentTime
            let diff = diffUTCTime end start
            let timeMs = round (realToFrac diff * 1000 :: Double)
            
            logInfoN $ "Optimization completed in " <> T.pack (show timeMs) <> "ms"
            
            case result of
                Right apiResult -> return $ fromAPIOptimizationResult apiResult timeMs
                Left err -> do
                    let msg = T.pack $ "Optimization failed: " ++ show err
                    logInfoN msg
                    return $ errorResult msg
  where
    errorResult msg = OptimizationResult
        { success = False
        , solution = []
        , objectiveValue = 0.0
        , iterations = 0
        , converged = False
        , message = Just msg
        , constraintViolations = []
        , convergenceHistory = Nothing
        , computationTimeMs = 0
        }

-- | Run multiple optimizations in batch
runBatchOptimization :: (MonadIO m, MonadLogger m) => SpaceConfigInput -> [OptimizationInput] -> m [OptimizationResult]
runBatchOptimization spaceInput inputs = do
    logInfoN $ "Batch optimization started with " <> T.pack (show $ length inputs) <> " inputs"
    results <- mapM (runOptimization spaceInput) inputs
    logInfoN "Batch optimization completed"
    return results
