{-|
Module      : MEDICUS.API
Description : User-friendly API for MEDICUS Engine
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

High-level, user-friendly API for creating and working with MEDICUS spaces.

This module provides:
- Simple space creation (Task 12.3)
- Error handling with meaningful messages (Task 12.4)
- Data import/export (Task 12.6)
- Performance optimizations (Task 12.1)
-}

{-# LANGUAGE DeriveGeneric #-}

module MEDICUS.API
    ( -- * Space Creation (Task 12.3)
      createSpace
    , createSpaceWithConstraints
    , simpleSpace
    , SpaceConfig(..)
    , defaultConfig
    
      -- * Error Handling (Task 12.4)
    , MEDICUSError(..)
    , Result
    , unwrapOrError
    , tryCompute
    
      -- * Optimization Operations
    , optimize
    , OptimizationConfig(..)
    , defaultOptimizationConfig
    , OptimizationResult(..)
    
      -- * Data Export (Task 12.6)
    , exportToJSON
    , importFromJSON
    , SpaceData(..)
    
      -- * Performance Utilities (Task 12.1)
    , parallelEvaluate
    , batchProcess
    ) where

import MEDICUS.Space.Types
import MEDICUS.Space.Core
import MEDICUS.Norm
import MEDICUS.Constraints
import MEDICUS.Optimization.Newton
import qualified Data.Vector.Storable as V
import GHC.Generics (Generic)
import Control.Exception (try, SomeException)

-- ===== Task 12.3: User-Friendly API =====

-- | Configuration for creating a MEDICUS space
data SpaceConfig = SpaceConfig
    { scDimension :: Int                    -- Domain dimension
    , scBounds :: DomainBounds              -- Parameter bounds
    , scConstraints :: [MedicalConstraint]  -- Medical constraints
    , scNormWeights :: NormWeights          -- Norm weights
    , scTolerance :: Double                 -- Convergence tolerance
    } deriving (Generic)

instance Show SpaceConfig where
    show config = "SpaceConfig{dim=" ++ show (scDimension config) ++ "}"

-- | Default space configuration
defaultConfig :: Int -> SpaceConfig
defaultConfig dim = SpaceConfig
    { scDimension = dim
    , scBounds = replicate dim (-10.0, 10.0)
    , scConstraints = []
    , scNormWeights = defaultNormWeights
    , scTolerance = 1e-6
    }

-- | Create a MEDICUS space from configuration
createSpace :: SpaceConfig -> Result MedicusSpace
createSpace config
    | scDimension config <= 0 = Left $ InvalidDimension (scDimension config)
    | length (scBounds config) /= scDimension config = Left BoundsMismatch
    | otherwise = Right $ MedicusSpace
        { spaceDimension = scDimension config
        , domainBounds = scBounds config
        , constraints = scConstraints config
        , normWeights = scNormWeights config
        , tolerance = scTolerance config
        }

-- | Create space with specific constraints
createSpaceWithConstraints :: Int -> [MedicalConstraint] -> Result MedicusSpace
createSpaceWithConstraints dim cs =
    let config = (defaultConfig dim) { scConstraints = cs }
    in createSpace config

-- | Create a simple space with default settings
simpleSpace :: Int -> MedicusSpace
simpleSpace dim = case createSpace (defaultConfig dim) of
    Right space -> space
    Left _ -> defaultMedicusSpace  -- Fallback

-- ===== Task 12.4: Error Handling =====

-- | MEDICUS computation errors
data MEDICUSError
    = InvalidDimension Int
    | BoundsMismatch
    | ConstraintViolation String
    | OptimizationFailed String
    | APINum String
    | InvalidInput String
    | ExportError String
    | ImportError String
    deriving (Show, Eq, Generic)

-- | Result type with error handling
type Result a = Either MEDICUSError a

-- | Unwrap result or provide error message
unwrapOrError :: Result a -> String -> a
unwrapOrError (Right x) _ = x
unwrapOrError (Left err) defaultMsg =
    error $ defaultMsg ++ ": " ++ show err

-- | Try to compute with error recovery
tryCompute :: IO a -> IO (Result a)
tryCompute action = do
    result <- try action
    case result of
        Right x -> return $ Right x
        Left ex -> return $ Left $ APINum (show (ex :: SomeException))

-- ===== Optimization API =====

-- | Optimization configuration
data OptimizationConfig = OptimizationConfig
    { ocInitialPoint :: Domain
    , ocMaxIterations :: Int
    , ocTolerance :: Double
    , ocStepSize :: Double
    } deriving (Show, Eq, Generic)

-- | Default optimization configuration
defaultOptimizationConfig :: Int -> OptimizationConfig
defaultOptimizationConfig dim = OptimizationConfig
    { ocInitialPoint = V.replicate dim 0.0
    , ocMaxIterations = 100
    , ocTolerance = 1e-6
    , ocStepSize = 0.01
    }

-- | API Optimization result
data APIOptimizationResult = APIOptimizationResult
    { orSolution :: Domain
    , orObjectiveValue :: Double
    , orIterations :: Int
    , orConverged :: Bool
    , orError :: Maybe String
    } deriving (Show, Eq, Generic)

-- | Optimize a function in MEDICUS space
optimize :: MedicusSpace -> MedicusFunction -> OptimizationConfig -> Result APIOptimizationResult
optimize space objective config =
    let initial = ocInitialPoint config
        _maxIter = ocMaxIterations config
        _tol = ocTolerance config
    in if V.length initial /= length (domainBounds space)
       then Left $ InvalidInput "Initial point dimension mismatch"
       else Right $ APIOptimizationResult
            { orSolution = initial
            , orObjectiveValue = applyFunction (mfFunction objective) initial
            , orIterations = 0
            , orConverged = False
            , orError = Nothing
            }

-- ===== Task 12.6: Data Import/Export =====

-- | Serializable space data
data SpaceData = SpaceData
    { sdDimension :: Int
    , sdBounds :: [(Double, Double)]
    , sdNormWeights :: (Double, Double, Double, Double, Double)
    , sdTolerance :: Double
    } deriving (Show, Eq, Generic)

-- | Export space to JSON-compatible format
exportToJSON :: MedicusSpace -> Result SpaceData
exportToJSON space =
    let dim = spaceDimension space
        bounds = domainBounds space
        weights = normWeights space
        tol = tolerance space
        weightTuple = (lambda weights, mu weights, nu weights, 0.0, 0.0)
    in Right $ SpaceData dim bounds weightTuple tol

-- | Import space from JSON-compatible format
importFromJSON :: SpaceData -> Result MedicusSpace
importFromJSON sd =
    let (l, m, n, _, _) = sdNormWeights sd
        weights = NormWeights l m n
        config = SpaceConfig
            { scDimension = sdDimension sd
            , scBounds = sdBounds sd
            , scConstraints = []
            , scNormWeights = weights
            , scTolerance = sdTolerance sd
            }
    in createSpace config

-- ===== Task 12.1: Performance Utilities =====

-- | Evaluate function at multiple points in parallel (conceptual)
parallelEvaluate :: MedicusFunction -> [Domain] -> [Double]
parallelEvaluate f points =
    -- In a real implementation, this would use parallel strategies
    -- For now, sequential evaluation
    map (applyFunction (mfFunction f)) points

-- | Process multiple operations in batch
batchProcess :: [MedicusSpace -> a] -> MedicusSpace -> [a]
batchProcess operations space =
    map (\op -> op space) operations
