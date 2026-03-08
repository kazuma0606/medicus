{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Util.Conversion
Description : Type conversion utilities between GraphQL and MEDICUS Engine types
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com

This module provides conversion functions between GraphQL types and MEDICUS Engine types.
-}

module Util.Conversion
    ( -- * Space Configuration Conversion
      toMEDICUSSpaceConfig
    , fromMEDICUSSpaceConfig
    
      -- * Norm Weights Conversion
    , toMEDICUSNormWeights
    , fromMEDICUSNormWeights
    
      -- * Constraint Conversion
    , toMEDICUSConstraint
    , toMEDICUSConstraintType
    
      -- * Optimization Conversion
    , toMEDICUSOptimizationConfig
    , fromAPIOptimizationResult
    
      -- * Objective Function Conversion
    -- , toMEDICUSObjectiveFunction
    ) where

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Vector.Storable as V

-- GraphQL Types
import GraphQL.Types.Space
    ( SpaceConfigInput(..)
    , ConstraintInput(..)
    )
import GraphQL.Types.Common
    ( NormWeightsInput(..)
    , NormWeights(..)
    , ConstraintType(..)
    )
import GraphQL.Types.Optimization
    ( OptimizationInput(..)
    , OptimizationResult(..)
    , OptimizationOptions(..)
    )

-- MEDICUS Engine types
import qualified MEDICUS.API as MA
import qualified MEDICUS.Space.Types as MS
import qualified MEDICUS.Constraints as MC

-- * Space Configuration Conversion

-- | Convert GraphQL SpaceConfigInput to MEDICUS Engine SpaceConfig
toMEDICUSSpaceConfig :: SpaceConfigInput -> MA.SpaceConfig
toMEDICUSSpaceConfig config = MA.SpaceConfig
    { MA.scDimension = dimension config
    , MA.scBounds = replicate (dimension config) (-10.0, 10.0) -- Default bounds
    , MA.scConstraints = map toMEDICUSConstraint (constraints config)
    , MA.scNormWeights = toMEDICUSNormWeights (normWeights config)
    , MA.scTolerance = 1e-6 -- Default tolerance
    }

-- | Convert MEDICUS Engine SpaceConfig to GraphQL SpaceConfigInput (Partial)
fromMEDICUSSpaceConfig :: MA.SpaceConfig -> SpaceConfigInput
fromMEDICUSSpaceConfig config = SpaceConfigInput
    { dimension = MA.scDimension config
    , normWeights = fromMEDICUSNormWeights (MA.scNormWeights config)
    , constraints = [] -- Note: mapping back from MedicalConstraint is complex due to evaluator function
    }

-- * Norm Weights Conversion

-- | Convert GraphQL NormWeightsInput to MEDICUS Engine NormWeights
toMEDICUSNormWeights :: NormWeightsInput -> MS.NormWeights
toMEDICUSNormWeights weights = MS.NormWeights
    { MS.lambda = lambda (weights :: NormWeightsInput)
    , MS.mu = mu (weights :: NormWeightsInput)
    , MS.nu = nu (weights :: NormWeightsInput)
    }

-- | Convert MEDICUS Engine NormWeights to GraphQL NormWeightsInput
fromMEDICUSNormWeights :: MS.NormWeights -> NormWeightsInput
fromMEDICUSNormWeights weights = NormWeightsInput
    { lambda = MS.lambda weights
    , mu = MS.mu weights
    , nu = MS.nu weights
    }

-- * Constraint Conversion

-- | Convert GraphQL ConstraintInput to MEDICUS Engine MedicalConstraint
toMEDICUSConstraint :: ConstraintInput -> MS.MedicalConstraint
toMEDICUSConstraint constraint = 
    case constraintType constraint of
        PrivacyProtection -> MC.createPrivacyConstraint (threshold constraint)
        EmergencyAccess -> MC.createEmergencyConstraint (threshold constraint)
        SystemAvailability -> MC.createAvailabilityConstraint (threshold constraint)
        RegulatoryCompliance -> MC.createComplianceConstraint
        CustomConstraint -> MC.createPrivacyConstraint (threshold constraint) -- Fallback

-- | Convert GraphQL ConstraintType to MEDICUS Engine ConstraintType (Basic mapping)
toMEDICUSConstraintType :: ConstraintType -> MS.ConstraintType
toMEDICUSConstraintType _ = MS.Inequality 0.5 -- Default placeholder

-- * Optimization Conversion

-- | Convert GraphQL OptimizationInput to MEDICUS Engine OptimizationConfig
toMEDICUSOptimizationConfig :: OptimizationInput -> MA.OptimizationConfig
toMEDICUSOptimizationConfig input = MA.OptimizationConfig
    { MA.ocInitialPoint = V.fromList (initialPoint input)
    , MA.ocMaxIterations = maybe 100 maxIterations (options input)
    , MA.ocTolerance = maybe 1e-6 tolerance (options input)
    , MA.ocStepSize = 0.01 -- Default step size
    }

-- | Convert MEDICUS Engine OptimizationResult to GraphQL OptimizationResult
fromAPIOptimizationResult :: MA.APIOptimizationResult -> Int -> OptimizationResult
fromAPIOptimizationResult result timeMs = OptimizationResult
    { success = MA.orConverged result
    , solution = V.toList (MA.orSolution result)
    , objectiveValue = MA.orObjectiveValue result
    , iterations = MA.orIterations result
    , converged = MA.orConverged result
    , message = T.pack <$> MA.orError result
    , constraintViolations = [] -- TODO: map from engine
    , convergenceHistory = Nothing
    , computationTimeMs = timeMs
    }
