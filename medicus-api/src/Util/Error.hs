{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Util.Error
Description : Error conversion utilities between MEDICUS Engine and GraphQL
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com

This module provides error conversion functions between MEDICUS Engine errors
and GraphQL error types.
-}

module Util.Error
    ( -- * Error Types
      MEDICUSError(..)
    
      -- * Error Conversion
    , toGraphQLValidationError
    , toGraphQLValidationErrors
    , medicusErrorToGraphQL
    , formatMEDICUSError
    
      -- * Error Code Mapping
    , mapMEDICUSErrorCode
    
      -- * Validation Helpers
    , validateDimensionRange
    , validateNormWeightsSum
    , validateConstraintDimensions
    ) where

import Data.Text (Text)
import qualified Data.Text as T
import GraphQL.Types.Error
    ( ValidationError(..)
    , ValidationWarning(..)
    , ErrorCode(..)
    )

-- TODO: Import MEDICUS Engine error types when dependency is enabled
-- import qualified MEDICUS.Error as ME

-- Placeholder MEDICUS Engine error types
data MEDICUSError
    = MEDICUSInvalidDimension Text
    | MEDICUSInvalidNormWeights Text
    | MEDICUSInvalidConstraint Text
    | MEDICUSDimensionMismatch Text
    | MEDICUSOptimizationFailed Text
    | MEDICUSConvergenceFailed Text
    | MEDICUSUnknownError Text
    deriving (Eq, Show)

-- * Error Conversion

-- | Convert a single MEDICUS error to GraphQL ValidationError
toGraphQLValidationError :: MEDICUSError -> ValidationError
toGraphQLValidationError (MEDICUSInvalidDimension msg) = ValidationError
    { field = "dimension"
    , errorMessage = msg
    , errorCode = InvalidDimension
    }
toGraphQLValidationError (MEDICUSInvalidNormWeights msg) = ValidationError
    { field = "normWeights"
    , errorMessage = msg
    , errorCode = InvalidNormWeights
    }
toGraphQLValidationError (MEDICUSInvalidConstraint msg) = ValidationError
    { field = "constraints"
    , errorMessage = msg
    , errorCode = InvalidConstraint
    }
toGraphQLValidationError (MEDICUSDimensionMismatch msg) = ValidationError
    { field = "dimension"
    , errorMessage = msg
    , errorCode = InvalidDimension  -- Using closest match
    }
toGraphQLValidationError (MEDICUSOptimizationFailed msg) = ValidationError
    { field = "optimization"
    , errorMessage = msg
    , errorCode = InternalError
    }
toGraphQLValidationError (MEDICUSConvergenceFailed msg) = ValidationError
    { field = "optimization"
    , errorMessage = msg
    , errorCode = ConvergenceFailure
    }
toGraphQLValidationError (MEDICUSUnknownError msg) = ValidationError
    { field = "unknown"
    , errorMessage = msg
    , errorCode = InternalError
    }

-- | Convert multiple MEDICUS errors to GraphQL ValidationErrors
toGraphQLValidationErrors :: [MEDICUSError] -> [ValidationError]
toGraphQLValidationErrors = map toGraphQLValidationError

-- | Generic MEDICUS error to GraphQL error conversion
medicusErrorToGraphQL :: MEDICUSError -> Text
medicusErrorToGraphQL err = formatMEDICUSError err

-- | Format MEDICUS error as user-friendly message
formatMEDICUSError :: MEDICUSError -> Text
formatMEDICUSError (MEDICUSInvalidDimension msg) =
    "Invalid dimension: " <> msg
formatMEDICUSError (MEDICUSInvalidNormWeights msg) =
    "Invalid norm weights: " <> msg
formatMEDICUSError (MEDICUSInvalidConstraint msg) =
    "Invalid constraint: " <> msg
formatMEDICUSError (MEDICUSDimensionMismatch msg) =
    "Dimension mismatch: " <> msg
formatMEDICUSError (MEDICUSOptimizationFailed msg) =
    "Optimization failed: " <> msg
formatMEDICUSError (MEDICUSConvergenceFailed msg) =
    "Convergence failed: " <> msg
formatMEDICUSError (MEDICUSUnknownError msg) =
    "Unknown error: " <> msg

-- * Error Code Mapping

-- | Map MEDICUS error code to GraphQL error code
mapMEDICUSErrorCode :: Text -> Text
mapMEDICUSErrorCode "invalid_dimension" = "INVALID_DIMENSION"
mapMEDICUSErrorCode "invalid_norm_weights" = "INVALID_NORM_WEIGHTS"
mapMEDICUSErrorCode "invalid_constraint" = "INVALID_CONSTRAINT"
mapMEDICUSErrorCode "dimension_mismatch" = "DIMENSION_MISMATCH"
mapMEDICUSErrorCode "optimization_failed" = "OPTIMIZATION_FAILED"
mapMEDICUSErrorCode "convergence_failed" = "CONVERGENCE_FAILED"
mapMEDICUSErrorCode code = "UNKNOWN_ERROR_" <> T.toUpper code

-- * Validation Helpers

-- | Validate dimension is within acceptable range
validateDimensionRange :: Int -> Maybe ValidationError
validateDimensionRange dim
    | dim <= 0 = Just $ ValidationError
        { field = "dimension"
        , errorMessage = "Dimension must be positive (> 0)"
        , errorCode = InvalidDimension
        }
    | dim > 1000 = Just $ ValidationError
        { field = "dimension"
        , errorMessage = "Dimension too large (max 1000)"
        , errorCode = InvalidDimension
        }
    | otherwise = Nothing

-- | Validate norm weights sum to 1.0
validateNormWeightsSum :: Double -> Double -> Double -> Maybe ValidationError
validateNormWeightsSum l m n
    | any (< 0) [l, m, n] = Just $ ValidationError
        { field = "normWeights"
        , errorMessage = "All norm weights must be non-negative"
        , errorCode = InvalidNormWeights
        }
    | abs (l + m + n - 1.0) > 1e-10 = Just $ ValidationError
        { field = "normWeights"
        , errorMessage = T.pack $ "Norm weights must sum to 1.0 (got " ++ show (l + m + n) ++ ")"
        , errorCode = InvalidNormWeights
        }
    | otherwise = Nothing

-- | Validate constraint dimensions are within space dimension
validateConstraintDimensions :: Int -> [Int] -> Maybe ValidationError
validateConstraintDimensions spaceDim constraintDims
    | null constraintDims = Just $ ValidationError
        { field = "constraints.dimensions"
        , errorMessage = "Constraint dimensions cannot be empty"
        , errorCode = InvalidConstraint
        }
    | any (< 0) constraintDims = Just $ ValidationError
        { field = "constraints.dimensions"
        , errorMessage = "Constraint dimension indices must be non-negative"
        , errorCode = InvalidConstraint
        }
    | any (>= spaceDim) constraintDims = Just $ ValidationError
        { field = "constraints.dimensions"
        , errorMessage = T.pack $ "Constraint dimension indices must be less than space dimension (" ++ show spaceDim ++ ")"
        , errorCode = InvalidDimension
        }
    | otherwise = Nothing
