{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Service.Validation
Description : Validation logic for MEDICUS space configurations
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com

This module provides validation logic for MEDICUS space configurations,
ensuring they meet the mathematical and medical requirements.
-}

module Service.Validation
    ( -- * Core Validation
      validateSpaceConfig
    , validateDimension
    , validateNormWeights
    , validateConstraints
    
      -- * Result Aggregation
    , aggregateValidation
    ) where

import Data.Text (Text)
import qualified Data.Text as T
import Data.Maybe (catMaybes)

-- GraphQL Types
import GraphQL.Types.Space
    ( SpaceConfigInput(..)
    , ConstraintInput(..)
    , ValidationResult(..)
    )
import GraphQL.Types.Common
    ( NormWeightsInput(..)
    )
import GraphQL.Types.Error
    ( ValidationError(..)
    , ValidationWarning(..)
    , ErrorCode(..)
    )

-- Utility Helpers
import Util.Error
    ( validateDimensionRange
    , validateNormWeightsSum
    )

-- | Validate a complete space configuration
validateSpaceConfig :: SpaceConfigInput -> ValidationResult
validateSpaceConfig config = aggregateValidation
    [ validateDimension (dimension config)
    , validateNormWeights (normWeights config)
    , validateConstraints (constraints config)
    ]

-- | Validate dimension
validateDimension :: Int -> [ValidationError]
validateDimension dim = catMaybes [validateDimensionRange dim]

-- | Validate norm weights
validateNormWeights :: NormWeightsInput -> [ValidationError]
validateNormWeights weights = catMaybes
    [ validateNormWeightsSum (lambda weights) (mu weights) (nu weights) ]

-- | Validate constraints
validateConstraints :: [ConstraintInput] -> [ValidationError]
validateConstraints [] = []
validateConstraints cs = catMaybes (zipWith validateConstraint [0..] cs)
  where
    validateConstraint :: Int -> ConstraintInput -> Maybe ValidationError
    validateConstraint idx c
        | threshold c < 0 = Just $ ValidationError
            { field = T.pack $ "constraints[" ++ show idx ++ "].threshold"
            , errorMessage = "Constraint threshold must be non-negative"
            , errorCode = InvalidConstraint
            }
        | otherwise = Nothing

-- | Aggregate multiple validation error lists into a ValidationResult
aggregateValidation :: [[ValidationError]] -> ValidationResult
aggregateValidation errorLists = 
    let allErrors = concat errorLists
    in ValidationResult
        { valid = null allErrors
        , errors = allErrors
        , warnings = [] -- Future: Add warning logic if needed
        }
