{-|
Module      : GraphQL.Types.Common
Description : Common GraphQL types
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Common types used across GraphQL schema.
-}

{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}

module GraphQL.Types.Common where

import Data.Morpheus.Types (GQLType)
import Data.Text (Text)
import GHC.Generics (Generic)

-- | Health status response
data HealthStatus = HealthStatus
    { status :: Text
    , service :: Text
    , version :: Text
    , timestamp :: Text
    } deriving (Show, Eq, Generic, GQLType)

-- | Constraint type enumeration
data ConstraintType
    = PrivacyProtection
    | EmergencyAccess
    | SystemAvailability
    | RegulatoryCompliance
    | CustomConstraint
    deriving (Show, Eq, Generic, GQLType)

-- | Norm weights input
data NormWeightsInput = NormWeightsInput
    { lambda :: Double  -- Constraint violation weight
    , mu :: Double      -- Entropy weight
    , nu :: Double      -- Thermal weight
    } deriving (Show, Eq, Generic, GQLType)

-- | Norm weights output
data NormWeights = NormWeights
    { nwLambda :: Double
    , nwMu :: Double
    , nwNu :: Double
    } deriving (Show, Eq, Generic, GQLType)
