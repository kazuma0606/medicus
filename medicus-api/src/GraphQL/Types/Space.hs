{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}

{- |
Module      : GraphQL.Types.Space
Description : Space-related GraphQL types
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

GraphQL types for MEDICUS space configuration and validation.
-}

module GraphQL.Types.Space where

import Data.Morpheus.Types (GQLType)
import Data.Text (Text)
import GHC.Generics (Generic)

import GraphQL.Types.Common (NormWeights, NormWeightsInput)
import GraphQL.Types.Error (ValidationError, ValidationWarning)

-- | Configuration for creating or validating a MEDICUS space
data SpaceConfigInput = SpaceConfigInput
    { dimension :: Int
    -- ^ The number of dimensions for the medical data space (1-1000)
    
    , normWeights :: NormWeightsInput
    -- ^ Weights for the combined norm (lambda, mu, nu)
    
    , constraints :: [ConstraintInput]
    -- ^ List of medical and security constraints to apply
    } deriving (Show, Eq, Generic, GQLType)

-- | Input for a single constraint
data ConstraintInput = ConstraintInput
    { constraintType :: ConstraintTypeInput
    -- ^ The type of constraint (e.g., Privacy, Emergency)
    
    , threshold :: Double
    -- ^ The security/medical threshold value (typically 0.0 to 1.0)
    
    , description :: Maybe Text
    -- ^ Optional description of the constraint's purpose
    } deriving (Show, Eq, Generic, GQLType)

-- | Available constraint types for input
data ConstraintTypeInput
    = PrivacyProtection
    | EmergencyAccess
    | SystemAvailability
    | RegulatoryCompliance
    | CustomConstraint
    deriving (Show, Eq, Generic, GQLType)

-- | Result of a space creation operation
data CreateSpaceResult = CreateSpaceResult
    { spaceId :: Text
    -- ^ Unique identifier for the created space
    
    , success :: Bool
    -- ^ Whether the operation was successful
    
    , message :: Maybe Text
    -- ^ Optional status or error message
    } deriving (Show, Eq, Generic, GQLType)

-- | Result of a space validation operation
data ValidationResult = ValidationResult
    { valid :: Bool
    -- ^ True if the configuration meets all requirements
    
    , errors :: [ValidationError]
    -- ^ List of fatal validation errors
    
    , warnings :: [ValidationWarning]
    -- ^ List of non-fatal warnings
    } deriving (Show, Eq, Generic, GQLType)

-- | Detailed information about an existing space
data SpaceInfo = SpaceInfo
    { infoSpaceId :: Text
    , infoDimension :: Int
    , infoConstraintCount :: Int
    , infoNormWeights :: NormWeights
    } deriving (Show, Eq, Generic, GQLType)
