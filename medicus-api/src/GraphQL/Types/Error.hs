{-|
Module      : GraphQL.Types.Error
Description : Error-related GraphQL types
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

GraphQL types for error handling and validation.
-}

{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}

module GraphQL.Types.Error where

import Data.Morpheus.Types (GQLType)
import Data.Text (Text)
import GHC.Generics (Generic)

-- | Error code enumeration
data ErrorCode
    = InvalidDimension
    | InvalidConstraint
    | InvalidNormWeights
    | NumericalInstability
    | ConvergenceFailure
    | ResourceNotFound
    | InternalError
    deriving (Show, Eq, Generic, GQLType)

-- | Validation error
data ValidationError = ValidationError
    { field :: Text
    , errorMessage :: Text
    , errorCode :: ErrorCode
    } deriving (Show, Eq, Generic, GQLType)

-- | Validation warning
data ValidationWarning = ValidationWarning
    { warningField :: Text
    , warningMessage :: Text
    } deriving (Show, Eq, Generic, GQLType)

-- | Generic API error
data APIError = APIError
    { code :: ErrorCode
    , message :: Text
    , suggestions :: [Text]
    } deriving (Show, Eq, Generic, GQLType)
