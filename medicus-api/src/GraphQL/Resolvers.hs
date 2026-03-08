{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : GraphQL.Resolvers
Description : GraphQL root resolver
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

This module integrates all query and mutation resolvers into the root resolver.
-}

module GraphQL.Resolvers
    ( rootResolver
    ) where

import Data.Morpheus.Types (RootResolver(..), Undefined(..))

-- Schema
import GraphQL.Schema

-- Query Resolvers
import GraphQL.Query.Space (resolveValidateSpace, resolveListConstraints)
import GraphQL.Query.Health (resolveHealth)

-- Mutation Resolvers
import GraphQL.Mutation.Space (resolveCreateSpace, resolveDeleteSpace)
import GraphQL.Mutation.Optimization (resolveOptimize, resolveOptimizeBatch)

-- | Root resolver
-- Integrates all sub-resolvers for the GraphQL API.
rootResolver :: RootResolver IO () Query Mutation Undefined
rootResolver = RootResolver
    { queryResolver = Query
        { validateSpace = resolveValidateSpace
        , listAvailableConstraints = resolveListConstraints
        , health = resolveHealth
        }
    , mutationResolver = Mutation
        { createSpace = resolveCreateSpace
        , deleteSpace = resolveDeleteSpace
        , optimize = resolveOptimize
        , optimizeBatch = resolveOptimizeBatch
        }
    , subscriptionResolver = Undefined
    }
