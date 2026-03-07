{-|
Module      : MEDICUS.Norm
Description : MEDICUS norm computation
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

This module implements the computation of MEDICUS norm:
‖f‖_M = ‖f‖_∞ + ‖∇f‖_∞ + λ·V_C(f) + μ·S_entropy(f) + ν·E_thermal(f)

The norm combines:
- Uniform norm: maximum absolute value
- Gradient norm: maximum gradient magnitude
- Constraint penalty: weighted sum of squared violations
- Entropy term: statistical mechanical description
- Thermal term: emergency parameter effects
-}

module MEDICUS.Norm
    ( -- * Norm Computation
      medicusNorm
    , uniformNorm
    , gradientNorm
    , constraintViolationPenalty
    , entropyTerm
    , thermalTerm
    
      -- * Helper Functions
    , vectorNorm
    , supremum
    , generateSampleGrid
    , generateAdaptiveSamples
    ) where

import MEDICUS.Space.Types
import qualified Data.Vector.Storable as V

-- | Compute MEDICUS norm for a function
-- ‖f‖_M = ‖f‖_∞ + ‖∇f‖_∞ + λ·V_C(f) + μ·S_entropy(f) + ν·E_thermal(f)
medicusNorm :: MedicusSpace -> MedicusFunction -> Double
medicusNorm space mf = 
    uNorm + gNorm + lambda' * cvPenalty + mu' * entropy + nu' * thermal
  where
    NormWeights lambda' mu' nu' = normWeights space
    bounds = domainBounds space
    
    uNorm = uniformNorm bounds (mfFunction mf)
    gNorm = gradientNorm bounds (mfGradient mf)
    cvPenalty = constraintViolationPenalty space mf
    entropy = entropyTerm mf
    thermal = thermalTerm mf

-- | Euclidean norm of a vector
vectorNorm :: V.Vector Double -> Double
vectorNorm v = sqrt $ V.sum $ V.map (\x -> x * x) v

-- | Compute supremum (maximum) of a list
-- Uses a safe version with default value
supremum :: [Double] -> Double
supremum [] = 0.0
supremum xs = maximum $ map abs xs

-- | Generate a uniform sample grid over domain bounds
-- For each dimension, generates n evenly-spaced points
generateSampleGrid :: DomainBounds -> Int -> [Domain]
generateSampleGrid bounds samplesPerDim =
    let gridPoints = map (generateDimGrid samplesPerDim) bounds
        combinations = sequence gridPoints
    in map V.fromList combinations
  where
    generateDimGrid :: Int -> (Double, Double) -> [Double]
    generateDimGrid n (lo, hi)
        | n <= 1 = [(lo + hi) / 2]
        | otherwise = 
            let step = (hi - lo) / fromIntegral (n - 1)
            in [lo + step * fromIntegral i | i <- [0..n-1]]

-- | Generate adaptive samples with denser sampling near boundaries
generateAdaptiveSamples :: DomainBounds -> Int -> [Domain]
generateAdaptiveSamples bounds samplesPerDim =
    let regularSamples = generateSampleGrid bounds samplesPerDim
        boundarySamples = generateBoundarySamples bounds
    in regularSamples ++ boundarySamples
  where
    generateBoundarySamples :: DomainBounds -> [Domain]
    generateBoundarySamples bs =
        let n = length bs
            -- Generate corner points
            corners = sequence [[lo, hi] | (lo, hi) <- bs]
            -- Generate face centers
            faceCenters = [V.fromList [if i == j then val else (lo + hi) / 2 
                                      | (j, (lo, hi)) <- zip [0..] bs]
                          | i <- [0..n-1], val <- [fst (bs !! i), snd (bs !! i)]]
        in map V.fromList corners ++ faceCenters

-- | Uniform norm ‖f‖_∞ = sup_{x∈Ω} |f(x)|
-- Computed by sampling the domain and finding maximum absolute value
uniformNorm :: DomainBounds -> MedicalFunction -> Double
uniformNorm bounds f = 
    let samples = generateSampleGrid bounds 7  -- 7^n sample points
        values = map (abs . applyFunction f) samples
    in supremum values

-- | Gradient norm ‖∇f‖_∞ = sup_{x∈Ω} ‖∇f(x)‖
-- Computed by sampling and finding maximum gradient magnitude
gradientNorm :: DomainBounds -> Gradient -> Double
gradientNorm bounds grad = 
    let samples = generateSampleGrid bounds 7
        gradientMagnitudes = map (vectorNorm . grad) samples
    in supremum gradientMagnitudes

-- | Constraint violation penalty V_C(f) = Σ_c max(0, violation_c(f))²
-- Sum of squared violations over all constraints
constraintViolationPenalty :: MedicusSpace -> MedicusFunction -> Double
constraintViolationPenalty _space mf = sum $ map violation (mfConstraints mf)

-- | Entropy term S_entropy(f)
-- Statistical mechanical representation of personnel variation
-- Based on function value distribution entropy
entropyTerm :: MedicusFunction -> Double
entropyTerm mf = 
    let samples = generateSampleGrid defaultDomainBounds 5
        values = map (applyFunction (mfFunction mf)) samples
        -- Compute distribution entropy
        distribution = normalizeDistribution values
        entropy = -sum [p * log (p + 1e-10) | p <- distribution, p > 0]
    in entropy
  where
    -- Normalize values to probability distribution
    normalizeDistribution :: [Double] -> [Double]
    normalizeDistribution vals =
        let positiveVals = map (\x -> max 0 (abs x)) vals
            total = sum positiveVals
        in if total > 0 
           then map (/ total) positiveVals
           else replicate (length vals) (1.0 / fromIntegral (length vals))

-- | Thermal term E_thermal(f)
-- Boltzmann distribution effects for emergency parameters
-- Based on function value variation (thermal fluctuations analogy)
thermalTerm :: MedicusFunction -> Double
thermalTerm mf = 
    let samples = generateSampleGrid defaultDomainBounds 5
        values = map (applyFunction (mfFunction mf)) samples
        -- Compute thermal energy: variance of function values
        mean = sum values / fromIntegral (length values)
        variance = sum [(v - mean) ^ (2 :: Int) | v <- values] / fromIntegral (length values)
        -- Thermal energy is proportional to variance
        thermalEnergy = sqrt variance
    in thermalEnergy
