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
    ( -- * Error Conversion
      toGraphQLValidationError
    , toGraphQLValidationErrors
    , medicusErrorToGraphQL
    , formatMEDICUSError
    
      -- * Error Code Mapping
    , mapMEDICUSErrorCode
    
      -- * Validation Helpers
    , validateDimensionRange
    , validateNormWeightsSum
    , validateConstraintDimensions
    
      -- * API Errors
    , getErrorSuggestions
    , makeAPIError
    ) where

import Data.Text (Text)
import qualified Data.Text as T
import GraphQL.Types.Error
    ( ValidationError(..)
    , ValidationWarning(..)
    , APIError(..)
    , ErrorCode(..)
    )

-- MEDICUS Engine integration
import qualified MEDICUS.API as MA

-- * Error Conversion

-- | Convert a single MEDICUS error to GraphQL ValidationError
toGraphQLValidationError :: MA.MEDICUSError -> ValidationError
toGraphQLValidationError (MA.InvalidDimension dim) = ValidationError
    { field = "dimension"
    , errorMessage = T.pack $ "Invalid dimension: " ++ show dim
    , errorCode = InvalidDimension
    }
toGraphQLValidationError MA.BoundsMismatch = ValidationError
    { field = "dimension"
    , errorMessage = "Dimension bounds mismatch"
    , errorCode = InvalidDimension
    }
toGraphQLValidationError (MA.ConstraintViolation msg) = ValidationError
    { field = "constraints"
    , errorMessage = T.pack msg
    , errorCode = InvalidConstraint
    }
toGraphQLValidationError (MA.OptimizationFailed msg) = ValidationError
    { field = "optimization"
    , errorMessage = T.pack msg
    , errorCode = InternalError
    }
toGraphQLValidationError (MA.APINum msg) = ValidationError
    { field = "optimization"
    , errorMessage = T.pack msg
    , errorCode = InternalError
    }
toGraphQLValidationError (MA.InvalidInput msg) = ValidationError
    { field = "input"
    , errorMessage = T.pack msg
    , errorCode = InternalError
    }
toGraphQLValidationError (MA.ExportError msg) = ValidationError
    { field = "export"
    , errorMessage = T.pack msg
    , errorCode = InternalError
    }
toGraphQLValidationError (MA.ImportError msg) = ValidationError
    { field = "import"
    , errorMessage = T.pack msg
    , errorCode = InternalError
    }

-- | Convert multiple MEDICUS errors to GraphQL ValidationErrors
toGraphQLValidationErrors :: [MA.MEDICUSError] -> [ValidationError]
toGraphQLValidationErrors = map toGraphQLValidationError

-- | Generic MEDICUS error to GraphQL error conversion
medicusErrorToGraphQL :: MA.MEDICUSError -> Text
medicusErrorToGraphQL err = formatMEDICUSError err

-- | Format MEDICUS error as user-friendly message
formatMEDICUSError :: MA.MEDICUSError -> Text
formatMEDICUSError = T.pack . show

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

-- * API Errors

-- | Get helpful suggestions for specific error codes
getErrorSuggestions :: ErrorCode -> [Text]
getErrorSuggestions InvalidDimension = 
    [ "Ensure dimension is between 1 and 1000"
    , "Check that input vector size matches space dimension"
    ]
getErrorSuggestions InvalidNormWeights = 
    [ "Ensure lambda + mu + nu = 1.0"
    , "Check that all weights are non-negative"
    ]
getErrorSuggestions InvalidConstraint = 
    [ "Verify constraint thresholds are non-negative"
    , "Ensure custom constraint functions are valid"
    ]
getErrorSuggestions ConvergenceFailure = 
    [ "Try increasing maxIterations"
    , "Try a different initial point"
    , "Relax constraint tolerances"
    ]
getErrorSuggestions _ = ["Please contact technical support if the issue persists"]

-- | Create a standard APIError from a message and code
makeAPIError :: Text -> ErrorCode -> APIError
makeAPIError msg code' = APIError
    { message = msg
    , code = code'
    , suggestions = getErrorSuggestions code'
    }
