{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveFunctor #-}

{-|
Module      : MEDICUS.Space.Types
Description : Core type definitions for MEDICUS Space Theory
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

This module defines the fundamental types for MEDICUS space theory,
including domains, functions, constraints, and spaces.
-}

module MEDICUS.Space.Types
    ( -- * Domain Types
      Domain
    , DomainBounds
    , domainDimension
    , domainZero
    , domainFromList
    , inDomainBounds
    
      -- * Function Types
    , MedicalFunction(..)
    , Gradient
    , Hessian
    , makeMedicalFunction
    
      -- * Constraint Types
    , Constraint(..)
    , ConstraintId
    , ConstraintResult(..)
    , ConstraintType(..)
    , ConstraintPriority(..)
    , MedicalConstraint(..)
    
      -- * MEDICUS Space Types
    , MedicusSpace(..)
    , NormWeights(..)
    , MedicusFunction(..)
    
      -- * Default Values
    , defaultNormWeights
    , defaultDomainBounds
    ) where

import qualified Data.Vector.Storable as V
import GHC.Generics (Generic)
import Control.DeepSeq (NFData)

-- | Parameter domain Ω ⊆ ℝⁿ
type Domain = V.Vector Double

-- | Domain bounds for each dimension
type DomainBounds = [(Double, Double)]

-- | Get dimension of a domain
domainDimension :: Domain -> Int
domainDimension = V.length

-- | Create zero vector in given dimension
domainZero :: Int -> Domain
domainZero n = V.replicate n 0.0

-- | Create domain from list
domainFromList :: [Double] -> Domain
domainFromList = V.fromList

-- | Check if a point is within domain bounds
inDomainBounds :: DomainBounds -> Domain -> Bool
inDomainBounds bounds theta =
    length bounds == V.length theta &&
    all checkBound (zip (V.toList theta) bounds)
  where
    checkBound (x, (lo, hi)) = x >= lo && x <= hi

-- | Medical function f: Ω → ℝ
newtype MedicalFunction = MedicalFunction
    { applyFunction :: Domain -> Double
    }

-- | Create a medical function from a pure function
makeMedicalFunction :: (Domain -> Double) -> MedicalFunction
makeMedicalFunction = MedicalFunction

-- | Gradient ∇f: Ω → ℝⁿ
type Gradient = Domain -> V.Vector Double

-- | Hessian ∇²f: Ω → ℝⁿˣⁿ (represented as nested vectors)
type Hessian = Domain -> [[Double]]

-- | Constraint identifier
type ConstraintId = String

-- | Constraint function type
newtype Constraint = Constraint
    { checkConstraint :: MedicalFunction -> Bool
    }

-- | Constraint evaluation result
data ConstraintResult = ConstraintResult
    { constraintId :: ConstraintId
    , satisfied :: Bool
    , violation :: Double  -- max(0, violation)²
    } deriving (Show, Eq, Generic)

instance NFData ConstraintResult

-- | Type of constraint
data ConstraintType
    = Equality Double      -- g(x) = c
    | Inequality Double    -- g(x) ≥ c
    | Custom (Domain -> Bool)

-- | Priority level for constraints
data ConstraintPriority
    = Critical    -- Must be satisfied (regulatory compliance)
    | Important   -- Should be satisfied (safety)
    | Preferred   -- Nice to have (efficiency)
    deriving (Show, Eq, Ord, Generic)

instance NFData ConstraintPriority

-- | Medical-specific constraint definition
data MedicalConstraint = MedicalConstraint
    { mcId :: ConstraintId
    , mcType :: ConstraintType
    , mcPriority :: ConstraintPriority
    , mcDescription :: String
    , mcEvaluator :: Domain -> Double
    }

-- | MEDICUS norm weight coefficients
data NormWeights = NormWeights
    { lambda :: Double  -- Constraint violation weight λ
    , mu :: Double      -- Entropy weight μ
    , nu :: Double      -- Thermal weight ν
    } deriving (Show, Eq, Generic)

instance NFData NormWeights

-- | Default norm weights
defaultNormWeights :: NormWeights
defaultNormWeights = NormWeights
    { lambda = 1.0
    , mu = 0.5
    , nu = 0.3
    }

-- | Default domain bounds (unit cube in 3D)
defaultDomainBounds :: DomainBounds
defaultDomainBounds = [(0, 1), (0, 1), (0, 1)]

-- | MEDICUS function space definition
data MedicusSpace = MedicusSpace
    { spaceDimension :: Int
    , domainBounds :: DomainBounds
    , constraints :: [MedicalConstraint]
    , normWeights :: NormWeights
    , tolerance :: Double
    }

-- | Complete MEDICUS function with derivatives
data MedicusFunction = MedicusFunction
    { mfFunction :: MedicalFunction
    , mfGradient :: Gradient
    , mfHessian :: Hessian
    , mfConstraints :: [ConstraintResult]
    }
