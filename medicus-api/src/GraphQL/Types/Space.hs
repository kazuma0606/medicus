{-|
Module      : GraphQL.Types.Space
Description : Space-related GraphQL types
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

GraphQL types for MEDICUS space configuration and validation.
-}

{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}

module GraphQL.Types.Space where

import Data.Morpheus.Types (GQLType)
import Data.Text (Text)
import GHC.Generics (Generic)
import GraphQL.Types.Common (NormWeightsInput, NormWeights, ConstraintType)
import GraphQL.Types.Error (ValidationError, ValidationWarning)

-- | Space configuration input
data SpaceConfigInput = SpaceConfigInput
    { dimension :: Int
    , normWeights :: NormWeightsInput
    , constraints :: [ConstraintInput]
    } deriving (Show, Eq, Generic, GQLType)

-- | Constraint input
data ConstraintInput = ConstraintInput
    { constraintType :: ConstraintType
    , threshold :: Double
    , description :: Maybe Text
    } deriving (Show, Eq, Generic, GQLType)

-- | Space creation result
data CreateSpaceResult = CreateSpaceResult
    { spaceId :: Text
    , success :: Bool
    , message :: Maybe Text
    } deriving (Show, Eq, Generic, GQLType)

-- | Validation result
data ValidationResult = ValidationResult
    { valid :: Bool
    , errors :: [ValidationError]
    , warnings :: [ValidationWarning]
    } deriving (Show, Eq, Generic, GQLType)

-- | Space information (for future use when DB is integrated)
data SpaceInfo = SpaceInfo
    { infoSpaceId :: Text
    , infoDimension :: Int
    , infoConstraintCount :: Int
    , infoNormWeights :: NormWeights
    } deriving (Show, Eq, Generic, GQLType)
