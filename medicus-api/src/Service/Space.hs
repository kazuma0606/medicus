{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Service.Space
Description : Service for MEDICUS space management
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com

This module provides service-level functions for creating, validating,
and managing MEDICUS spaces, integrating the engine with the API.
-}

module Service.Space
    ( -- * Space Operations
      createSpace
    , validateSpace
    , getSpaceInfo
    ) where

import Data.Text (Text)
import qualified Data.Text as T
import Control.Monad.IO.Class (MonadIO, liftIO)

-- GraphQL Types
import GraphQL.Types.Space
    ( SpaceConfigInput(..)
    , CreateSpaceResult(..)
    , ValidationResult(..)
    , SpaceInfo(..)
    )
import GraphQL.Types.Common
    ( NormWeights(..)
    )

-- MEDICUS Engine integration
import qualified MEDICUS.API as MA
import qualified MEDICUS.Space.Types as MS
import Util.Conversion (toMEDICUSSpaceConfig)
import Service.Validation (validateSpaceConfig)

-- | Create a MEDICUS space from configuration
createSpace :: MonadIO m => SpaceConfigInput -> m CreateSpaceResult
createSpace config = do
    -- 1. Validate the configuration first
    let vResult = validateSpaceConfig config
    if not (valid vResult)
        then return CreateSpaceResult
            { spaceId = ""
            , success = False
            , message = Just "Validation failed"
            }
        else do
            -- 2. Try to create the space in the engine
            let engineConfig = toMEDICUSSpaceConfig config
            let result = MA.createSpace engineConfig
            case result of
                Right _space -> do
                    -- In a real app, we would save this to a DB and get an ID
                    -- For now, we just return a success message
                    return CreateSpaceResult
                        { spaceId = "temp-space-id"
                        , success = True
                        , message = Just "Space created successfully"
                        }
                Left err -> return CreateSpaceResult
                    { spaceId = ""
                    , success = False
                    , message = Just $ T.pack $ show err
                    }

-- | Validate a MEDICUS space configuration without creating it
validateSpace :: MonadIO m => SpaceConfigInput -> m ValidationResult
validateSpace config = return $ validateSpaceConfig config

-- | Get information about a MEDICUS space
getSpaceInfo :: MonadIO m => Text -> m (Maybe SpaceInfo)
getSpaceInfo _spaceId = do
    -- Stub: In the future, this would fetch from a database
    return $ Just SpaceInfo
        { infoSpaceId = "temp-space-id"
        , infoDimension = 3
        , infoConstraintCount = 0
        , infoNormWeights = NormWeights 1.0 0.5 0.3
        }
