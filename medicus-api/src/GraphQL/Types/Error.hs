{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}

{- |
Module      : GraphQL.Types.Error
Description : Error-related GraphQL types
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Detailed error types and codes for the MEDICUS API.
-}

module GraphQL.Types.Error where

import Data.Morpheus.Types (GQLType)
import Data.Text (Text)
import GHC.Generics (Generic)

-- | Detailed validation error for specific fields
data ValidationError = ValidationError
    { field :: Text
    , errorMessage :: Text
    , errorCode :: ErrorCode
    } deriving (Show, Eq, Generic, GQLType)

-- | Validation warning (non-fatal)
data ValidationWarning = ValidationWarning
    { field :: Text
    , message :: Text
    , warningCode :: Text
    } deriving (Show, Eq, Generic, GQLType)

-- | Global API error response
data APIError = APIError
    { message :: Text
    , code :: ErrorCode
    , suggestions :: [Text]
    } deriving (Show, Eq, Generic, GQLType)

-- | Structured error codes for machine consumption
data ErrorCode
    = InvalidDimension     -- ^ Dimension out of range or mismatch
    | InvalidNormWeights   -- ^ Weights don't sum to 1.0 or are negative
    | InvalidConstraint    -- ^ Constraint parameters are invalid
    | NumericalInstability -- ^ Numerical precision issues
    | ConvergenceFailure   -- ^ Optimization failed to converge
    | ResourceNotFound     -- ^ Space or other resource not found
    | InternalError        -- ^ Unexpected server error
    | InvalidInput         -- ^ General malformed input
    deriving (Show, Eq, Generic, GQLType)
