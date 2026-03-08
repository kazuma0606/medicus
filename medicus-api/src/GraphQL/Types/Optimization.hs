{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}

{- |
Module      : GraphQL.Types.Optimization
Description : Optimization-related GraphQL types
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

GraphQL types for optimization input and results.
-}

module GraphQL.Types.Optimization where

import Data.Morpheus.Types (GQLType)
import Data.Text (Text)
import GHC.Generics (Generic)

-- | Detailed input for an optimization process
data OptimizationInput = OptimizationInput
    { objective :: ObjectiveFunctionInput
    -- ^ The medical objective function to optimize
    
    , initialPoint :: [Double]
    -- ^ Starting coordinates in the medicus space
    
    , options :: Maybe OptimizationOptions
    -- ^ Optional configuration for the optimizer
    } deriving (Show, Eq, Generic, GQLType)

-- | Definition of the objective function
data ObjectiveFunctionInput = ObjectiveFunctionInput
    { functionType :: ObjectiveType
    -- ^ The mathematical type of the function (e.g., Quadratic)
    
    , parameters :: Text
    -- ^ JSON-encoded parameters specific to the function type
    } deriving (Show, Eq, Generic, GQLType)

-- | Mathematical and medical objective types
data ObjectiveType
    = Linear
    | Quadratic
    | Nonlinear
    | CustomObjective
    deriving (Show, Eq, Generic, GQLType)

-- | Configuration options for the numerical optimizer
data OptimizationOptions = OptimizationOptions
    { maxIterations :: Maybe Int
    -- ^ Maximum number of iterations before stopping (default: 100)
    
    , tolerance :: Maybe Double
    -- ^ Convergence tolerance (default: 1e-6)
    
    , timeoutSeconds :: Maybe Int
    -- ^ Maximum execution time in seconds
    
    , parallelEvaluation :: Maybe Bool
    -- ^ Whether to use multi-core processing
    } deriving (Show, Eq, Generic, GQLType)

-- | The result of an optimization run
data OptimizationResult = OptimizationResult
    { success :: Bool
    -- ^ True if the optimization process completed without fatal errors
    
    , solution :: [Double]
    -- ^ The optimal point coordinates found
    
    , objectiveValue :: Double
    -- ^ The value of the objective function at the solution
    
    , iterations :: Int
    -- ^ Number of iterations actually performed
    
    , converged :: Bool
    -- ^ True if the solution met the convergence criteria
    
    , message :: Maybe Text
    -- ^ Descriptive status or error message
    
    , constraintViolations :: [ConstraintViolation]
    -- ^ Details of any constraints that were not fully met
    
    , convergenceHistory :: Maybe ConvergenceHistory
    -- ^ Step-by-step progress data (if requested)
    
    , computationTimeMs :: Int
    -- ^ Total processing time in milliseconds
    } deriving (Show, Eq, Generic, GQLType)

-- | Detail of a specific constraint violation
data ConstraintViolation = ConstraintViolation
    { constraintId :: Text
    -- ^ Identifier of the violated constraint
    
    , violation :: Double
    -- ^ Magnitude of the violation (0.0 means satisfied)
    
    , violationDescription :: Text
    } deriving (Show, Eq, Generic, GQLType)

-- | Data for convergence analysis and plotting
data ConvergenceHistory = ConvergenceHistory
    { objectiveValues :: [Double]
    , constraintViolationValues :: [Double]
    , iterationNumbers :: [Int]
    } deriving (Show, Eq, Generic, GQLType)

-- | Input for multiple optimization runs
data BatchOptimizationInput = BatchOptimizationInput
    { inputs :: [OptimizationInput]
    } deriving (Show, Eq, Generic, GQLType)
