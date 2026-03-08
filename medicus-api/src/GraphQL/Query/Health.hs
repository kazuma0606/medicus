{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : GraphQL.Query.Health
Description : GraphQL query resolvers for Health operations
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module GraphQL.Query.Health
    ( resolveHealth
    ) where

import Control.Monad.IO.Class (MonadIO, liftIO)
import qualified Data.Text as T
import Data.Time.Clock (getCurrentTime)
import Data.Time.Format (formatTime, defaultTimeLocale)

import GraphQL.Types.Common (HealthStatus(..))

-- | Resolver for health query
resolveHealth :: MonadIO m => m HealthStatus
resolveHealth = do
    now <- liftIO getCurrentTime
    let timestamp' = T.pack $ formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S%Z" now
    return $ HealthStatus
        { status = "healthy"
        , service = "medicus-api"
        , version = "0.1.0"
        , timestamp = timestamp'
        }
