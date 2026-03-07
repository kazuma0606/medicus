{-|
Module      : MEDICUS.UncertaintyPrinciple
Description : Uncertainty principle for security-efficiency tradeoff
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

Quantum-inspired uncertainty relations for medical systems.

This module implements:
- Security operator Ŝ (quantum representation of data protection)
- Efficiency operator Ê (quantum representation of operational efficiency)
- Commutator [Ŝ,Ê] (non-commutativity quantification)
- Heisenberg uncertainty relation ΔS·ΔE ≥ ½|⟨[Ŝ,Ê]⟩|
- Minimum uncertainty state (optimal security-efficiency balance)
-}

module MEDICUS.UncertaintyPrinciple
    ( -- * Operators (Task 8.1, 8.3)
      securityOperator
    , efficiencyOperator
    , computeOperatorEigenvalues
    , quantizeSecurityLevel
    , quantizeEfficiencyLevel
    , OperatorState(..)
    
      -- * Commutator (Task 8.5)
    , commutator
    , computeCommutator
    , quantifyNonCommutativity
    , composeOperators
    
      -- * Uncertainty Relations (Task 8.7)
    , uncertaintyRelation
    , computeStandardDeviation
    , uncertaintyBound
    , verifyUncertaintyInequality
    , UncertaintyMeasure(..)
    
      -- * Minimum Uncertainty State (Task 8.9)
    , minimumUncertaintyState
    , findOptimalBalance
    , constructCoherentState
    , MinimumUncertaintyState(..)
    ) where

import MEDICUS.Space.Types
import qualified Data.Vector.Storable as V

-- ===== Task 8.1: Security Operator Ŝ Implementation =====

-- | Operator state structure
data OperatorState = OperatorState
    { osEigenvalue :: Double      -- Eigenvalue (measurement outcome)
    , osEigenvector :: Domain     -- Eigenvector (state)
    , osQuantumNumber :: Int      -- Quantum number (discrete level)
    } deriving (Show, Eq)

-- | Security operator Ŝ
-- Represents data protection level as quantum observable
securityOperator :: MedicusSpace -> Domain -> Double
securityOperator space theta =
    let -- Security based on constraint satisfaction
        constraints' = constraints space
        satisfactionCount = length $ filter (\c -> evaluateConstraint c theta) constraints'
        totalConstraints = max 1 $ length constraints'
        -- Security level: 0 (worst) to 1 (best)
        securityLevel = fromIntegral satisfactionCount / fromIntegral totalConstraints
    in securityLevel
  where
    evaluateConstraint :: MedicalConstraint -> Domain -> Bool
    evaluateConstraint constraint point =
        mcEvaluator constraint point >= 0.0

-- | Compute operator eigenvalues
-- For discrete spectrum (simplified model)
computeOperatorEigenvalues :: Int -> [Double]
computeOperatorEigenvalues numLevels =
    [fromIntegral n / fromIntegral (max 1 (numLevels - 1)) | n <- [0..numLevels-1]]

-- | Quantize security level to discrete quantum numbers
quantizeSecurityLevel :: Double -> Int
quantizeSecurityLevel securityValue =
    let normalized = max 0.0 (min 1.0 securityValue)
        -- Map to discrete levels: 0, 1, 2, ..., 10
        level = floor (normalized * 10.0)
    in level

-- ===== Task 8.3: Efficiency Operator Ê Implementation =====

-- | Efficiency operator Ê
-- Represents operational efficiency as quantum observable
efficiencyOperator :: MedicusSpace -> Domain -> Double
efficiencyOperator space theta =
    let -- Efficiency based on parameter optimality
        -- Lower deviation from optimal center = higher efficiency
        optimalCenter = V.fromList $ replicate (spaceDimension space) 0.5
        deviation = V.zipWith (-) theta optimalCenter
        distance = sqrt $ V.sum $ V.map (\x -> x * x) deviation
        -- Efficiency: 1 (optimal) to 0 (worst)
        maxDeviation = 1.0
        efficiency = max 0.0 (1.0 - distance / maxDeviation)
    in efficiency

-- | Quantize efficiency level to discrete quantum numbers
quantizeEfficiencyLevel :: Double -> Int
quantizeEfficiencyLevel efficiencyValue =
    let normalized = max 0.0 (min 1.0 efficiencyValue)
        level = floor (normalized * 10.0)
    in level

-- ===== Task 8.5: Commutator Calculation =====

-- | Compute commutator [Ŝ,Ê] = ŜÊ - ÊŜ
-- Measures non-commutativity of security and efficiency adjustments
commutator :: MedicusSpace -> Domain -> Double
commutator space theta =
    computeCommutator space theta

-- | Compute commutator with finite differences
-- [Ŝ,Ê] = ∂Ŝ/∂θ · ∂Ê/∂θ (simplified to first order)
computeCommutator :: MedicusSpace -> Domain -> Double
computeCommutator space theta =
    let eps = 1e-5
        dim = V.length theta
        -- Compute gradients
        secGrad = V.generate dim $ \i ->
            let thetaPlus = V.imap (\j x -> if i == j then x + eps else x) theta
                thetaMinus = V.imap (\j x -> if i == j then x - eps else x) theta
                sPlus = securityOperator space thetaPlus
                sMinus = securityOperator space thetaMinus
            in (sPlus - sMinus) / (2 * eps)
        
        effGrad = V.generate dim $ \i ->
            let thetaPlus = V.imap (\j x -> if i == j then x + eps else x) theta
                thetaMinus = V.imap (\j x -> if i == j then x - eps else x) theta
                ePlus = efficiencyOperator space thetaPlus
                eMinus = efficiencyOperator space thetaMinus
            in (ePlus - eMinus) / (2 * eps)
        
        -- Commutator ~ cross product magnitude (simplified)
        commutatorValue = V.sum $ V.zipWith (*) secGrad effGrad
    in commutatorValue

-- | Quantify non-commutativity magnitude
quantifyNonCommutativity :: MedicusSpace -> Domain -> Double
quantifyNonCommutativity space theta =
    abs $ commutator space theta

-- | Compose operators: Ŝ(Ê(θ))
composeOperators :: MedicusSpace -> Domain -> Double
composeOperators space theta =
    let eff = efficiencyOperator space theta
        -- Apply security to efficiency (simplified: product)
        sec = securityOperator space theta
    in sec * eff

-- ===== Task 8.7: Uncertainty Relation Verification =====

-- | Uncertainty measure structure
data UncertaintyMeasure = UncertaintyMeasure
    { umSecurityStdDev :: Double      -- ΔS
    , umEfficiencyStdDev :: Double    -- ΔE
    , umProduct :: Double             -- ΔS·ΔE
    , umBound :: Double               -- ½|⟨[Ŝ,Ê]⟩|
    , umSatisfied :: Bool             -- ΔS·ΔE ≥ bound
    } deriving (Show, Eq)

-- | Verify Heisenberg uncertainty relation
-- ΔS·ΔE ≥ ½|⟨[Ŝ,Ê]⟩|
uncertaintyRelation :: MedicusSpace -> [Domain] -> UncertaintyMeasure
uncertaintyRelation space samples =
    let -- Compute expectation values
        secValues = map (securityOperator space) samples
        effValues = map (efficiencyOperator space) samples
        
        -- Standard deviations
        deltaSec = computeStandardDeviation secValues
        deltaEff = computeStandardDeviation effValues
        
        -- Commutator expectation value
        commValues = map (commutator space) samples
        commExpectation = sum commValues / fromIntegral (max 1 (length commValues))
        
        -- Uncertainty bound
        bound = 0.5 * abs commExpectation
        
        -- Product
        product' = deltaSec * deltaEff
        
        -- Check inequality
        inequalitySatisfied = product' >= bound - 1e-10  -- Allow small numerical error
        
    in UncertaintyMeasure deltaSec deltaEff product' bound inequalitySatisfied

-- | Compute standard deviation of measurements
computeStandardDeviation :: [Double] -> Double
computeStandardDeviation values =
    let n = length values
        mean = sum values / fromIntegral (max 1 n)
        variance = sum [(x - mean)^(2::Int) | x <- values] / fromIntegral (max 1 n)
    in sqrt variance

-- | Compute uncertainty bound ½|⟨[Ŝ,Ê]⟩|
uncertaintyBound :: MedicusSpace -> [Domain] -> Double
uncertaintyBound space samples =
    let commValues = map (commutator space) samples
        commExpectation = sum commValues / fromIntegral (max 1 (length commValues))
    in 0.5 * abs commExpectation

-- | Verify uncertainty inequality holds
verifyUncertaintyInequality :: MedicusSpace -> [Domain] -> Bool
verifyUncertaintyInequality space samples =
    let measure = uncertaintyRelation space samples
    in umSatisfied measure

-- ===== Task 8.9: Minimum Uncertainty State Search =====

-- | Minimum uncertainty state structure
data MinimumUncertaintyState = MinimumUncertaintyState
    { musParameter :: Domain
    , musSecurityValue :: Double
    , musEfficiencyValue :: Double
    , musUncertaintyProduct :: Double
    , musIsMinimal :: Bool  -- Equality condition satisfied
    } deriving (Show, Eq)

-- | Find minimum uncertainty state
-- State where ΔS·ΔE = ½|⟨[Ŝ,Ê]⟩| (equality)
minimumUncertaintyState :: MedicusSpace -> [Domain] -> MinimumUncertaintyState
minimumUncertaintyState space candidates =
    let -- Evaluate each candidate
        evaluations = [(theta, 
                       securityOperator space theta,
                       efficiencyOperator space theta,
                       abs (commutator space theta))
                      | theta <- candidates]
        
        -- Find state closest to equality condition
        scores = [(theta, sec, eff, comm, abs (sec * eff - 0.5 * comm))
                 | (theta, sec, eff, comm) <- evaluations]
        
        -- Minimum score = closest to equality
        (bestTheta, bestSec, bestEff, _bestComm, bestScore) = 
            minimumBy (\(_, _, _, _, s1) (_, _, _, _, s2) -> compare s1 s2) scores
        
        -- Check if equality is approximately satisfied
        isMinimal = bestScore < 0.1
        
    in MinimumUncertaintyState bestTheta bestSec bestEff (bestSec * bestEff) isMinimal
  where
    minimumBy :: (a -> a -> Ordering) -> [a] -> a
    minimumBy _ [] = error "minimumBy: empty list"
    minimumBy cmp (x:xs) = foldl (\a b -> if cmp a b == GT then b else a) x xs

-- | Find optimal security-efficiency balance
findOptimalBalance :: MedicusSpace -> DomainBounds -> Domain
findOptimalBalance space bounds =
    let samples = generateBalanceSamples bounds 20
        minState = minimumUncertaintyState space samples
    in musParameter minState

-- | Generate samples for balance search
generateBalanceSamples :: DomainBounds -> Int -> [Domain]
generateBalanceSamples bounds n =
    let gridPoints = sequence [linspace lo hi n | (lo, hi) <- bounds]
    in map V.fromList gridPoints
  where
    linspace :: Double -> Double -> Int -> [Double]
    linspace lo hi n' =
        let step = (hi - lo) / fromIntegral (max 1 (n' - 1))
        in [lo + step * fromIntegral i | i <- [0..n'-1]]

-- | Construct coherent state (minimum uncertainty state)
-- State that minimizes ΔS·ΔE
constructCoherentState :: MedicusSpace -> DomainBounds -> MinimumUncertaintyState
constructCoherentState space bounds =
    let samples = generateBalanceSamples bounds 25
    in minimumUncertaintyState space samples
