{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : GraphQL.Mutation.Space
Description : GraphQL mutation resolvers for Space operations
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module GraphQL.Mutation.Space
    ( resolveCreateSpace
    , resolveDeleteSpace
    ) where

import Control.Monad.IO.Class (MonadIO)
import Data.Text (Text)

import GraphQL.Schema (CreateSpaceArgs(..), DeleteSpaceArgs(..))
import GraphQL.Types.Space (CreateSpaceResult(..))
import Service.Space (createSpace)

-- | Resolver for createSpace mutation
resolveCreateSpace :: MonadIO m => CreateSpaceArgs -> m CreateSpaceResult
resolveCreateSpace args = createSpace (csConfig args)

-- | Resolver for deleteSpace mutation
resolveDeleteSpace :: MonadIO m => DeleteSpaceArgs -> m Bool
resolveDeleteSpace _args = return True -- Stub implementation
