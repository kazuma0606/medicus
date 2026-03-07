{-|
Module      : GraphQL.Types.Optimization
Description : Optimization-related GraphQL types
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

GraphQL types for optimization input and results.
-}

{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}

module GraphQL.Types.Optimization where

import Data.Morpheus.Types (GQLType)
import Data.Text (Text)
import GHC.Generics (Generic)

-- | Optimization input
data OptimizationInput = OptimizationInput
    { objective :: ObjectiveFunctionInput
    , initialPoint :: [Double]
    , options :: Maybe OptimizationOptions
    } deriving (Show, Eq, Generic, GQLType)

-- | Objective function input
data ObjectiveFunctionInput = ObjectiveFunctionInput
    { functionType :: ObjectiveType
    , parameters :: Text  -- JSON string for flexibility
    } deriving (Show, Eq, Generic, GQLType)

-- | Objective function type
data ObjectiveType
    = Linear
    | Quadratic
    | Nonlinear
    | CustomObjective
    deriving (Show, Eq, Generic, GQLType)

-- | Optimization options
data OptimizationOptions = OptimizationOptions
    { maxIterations :: Maybe Int
    , tolerance :: Maybe Double
    , timeoutSeconds :: Maybe Int
    , parallelEvaluation :: Maybe Bool
    } deriving (Show, Eq, Generic, GQLType)

-- | Optimization result
data OptimizationResult = OptimizationResult
    { success :: Bool
    , solution :: [Double]
    , objectiveValue :: Double
    , iterations :: Int
    , converged :: Bool
    , message :: Maybe Text
    , constraintViolations :: [ConstraintViolation]
    , convergenceHistory :: Maybe ConvergenceHistory
    , computationTimeMs :: Int
    } deriving (Show, Eq, Generic, GQLType)

-- | Constraint violation detail
data ConstraintViolation = ConstraintViolation
    { constraintId :: Text
    , violation :: Double
    , violationDescription :: Text
    } deriving (Show, Eq, Generic, GQLType)

-- | Convergence history
data ConvergenceHistory = ConvergenceHistory
    { objectiveValues :: [Double]
    , constraintViolationValues :: [Double]
    , iterationNumbers :: [Int]
    } deriving (Show, Eq, Generic, GQLType)

-- | Batch optimization input
data BatchOptimizationInput = BatchOptimizationInput
    { inputs :: [OptimizationInput]
    } deriving (Show, Eq, Generic, GQLType)
