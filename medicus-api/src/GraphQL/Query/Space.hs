{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : GraphQL.Query.Space
Description : GraphQL query resolvers for Space operations
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module GraphQL.Query.Space
    ( resolveValidateSpace
    , resolveListConstraints
    ) where

import Control.Monad.IO.Class (MonadIO, liftIO)

import GraphQL.Schema (ValidateSpaceArgs(..))
import GraphQL.Types.Space (ValidationResult(..))
import GraphQL.Types.Common (ConstraintType(..))
import Service.Validation (validateSpaceConfig)

-- | Resolver for validateSpace query
resolveValidateSpace :: MonadIO m => ValidateSpaceArgs -> m ValidationResult
resolveValidateSpace args = return $ validateSpaceConfig (config args)

-- | Resolver for listAvailableConstraints query
resolveListConstraints :: MonadIO m => m [ConstraintType]
resolveListConstraints = return
    [ PrivacyProtection
    , EmergencyAccess
    , SystemAvailability
    , RegulatoryCompliance
    , CustomConstraint
    ]
