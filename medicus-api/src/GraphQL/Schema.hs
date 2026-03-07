{-|
Module      : GraphQL.Schema
Description : GraphQL schema definition
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Complete GraphQL schema definition using Morpheus GraphQL.
Defines Query and Mutation root types.
-}

{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DuplicateRecordFields #-}

module GraphQL.Schema where

import Data.Morpheus.Types (GQLType, RootResolver(..), Undefined(..))
import Data.Text (Text)
import GHC.Generics (Generic)

-- Import our types
import GraphQL.Types.Common
import GraphQL.Types.Space
import GraphQL.Types.Optimization
import GraphQL.Types.Error

-- | Query root type
-- 
-- Available queries:
-- - validateSpace: Validate space configuration
-- - listAvailableConstraints: List available constraint types
-- - health: Health check endpoint
data Query m = Query
    { validateSpace :: ValidateSpaceArgs -> m ValidationResult
    -- ^ Validate a space configuration
    
    , listAvailableConstraints :: m [ConstraintType]
    -- ^ List all available constraint types
    
    , health :: m HealthStatus
    -- ^ Health check endpoint
    } deriving (Generic, GQLType)

-- | Mutation root type
--
-- Available mutations:
-- - createSpace: Create a new MEDICUS space
-- - deleteSpace: Delete a MEDICUS space
-- - optimize: Execute optimization
-- - optimizeBatch: Execute batch optimization
data Mutation m = Mutation
    { createSpace :: CreateSpaceArgs -> m CreateSpaceResult
    -- ^ Create a new MEDICUS space
    
    , deleteSpace :: DeleteSpaceArgs -> m Bool
    -- ^ Delete a MEDICUS space (returns success flag)
    
    , optimize :: OptimizeArgs -> m OptimizationResult
    -- ^ Execute single optimization
    
    , optimizeBatch :: OptimizeBatchArgs -> m [OptimizationResult]
    -- ^ Execute batch optimization
    } deriving (Generic, GQLType)

-- | Query arguments

-- | Arguments for validateSpace query
data ValidateSpaceArgs = ValidateSpaceArgs
    { config :: SpaceConfigInput
    } deriving (Generic, GQLType)

-- | Mutation arguments

-- | Arguments for createSpace mutation
data CreateSpaceArgs = CreateSpaceArgs
    { csConfig :: SpaceConfigInput
    } deriving (Generic, GQLType)

-- | Arguments for deleteSpace mutation
data DeleteSpaceArgs = DeleteSpaceArgs
    { spaceId :: Text
    } deriving (Generic, GQLType)

-- | Arguments for optimize mutation
data OptimizeArgs = OptimizeArgs
    { input :: OptimizationInput
    } deriving (Generic, GQLType)

-- | Arguments for optimizeBatch mutation
data OptimizeBatchArgs = OptimizeBatchArgs
    { batchInput :: BatchOptimizationInput
    } deriving (Generic, GQLType)

-- | Root resolver type
-- This will be implemented in GraphQL.Resolvers
type APISchema = RootResolver IO () Query Mutation Undefined
