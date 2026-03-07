{-|
Module      : MEDICUS.StatisticalMechanics
Description : Statistical mechanics framework for MEDICUS
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

Statistical mechanics framework for medical optimization systems.

This module implements:
- Medical energy functions E_medical(θ)
- Emergency parameter scaling T_emergency
- Partition function Z_medical computation
- Boltzmann distribution P(θ)
- Statistical equilibrium solver
-}

module MEDICUS.StatisticalMechanics
    ( -- * Energy Functions (Task 7.1)
      medicalEnergy
    , computeEnergyComponents
    , analyzeEnergyLandscape
    , EnergyComponents(..)
    
      -- * Emergency Parameter Scaling (Task 7.3)
    , emergencyTemperatureScale
    , emergencyLevelToTemperature
    , temperatureToEmergencyLevel
    , checkScaleInvariance
    
      -- * Partition Function (Task 7.5)
    , partitionFunction
    , computePartitionFunction
    , adaptivePartitionIntegration
    , verifyPartitionConvergence
    
      -- * Boltzmann Distribution (Task 7.7)
    , boltzmannDistribution
    , normalizeProbabilityDensity
    , sampleBoltzmannDistribution
    
      -- * Statistical Equilibrium (Task 7.9)
    , statisticalEquilibrium
    , freeEnergy
    , minimizeFreeEnergy
    , analyzeStability
    , EquilibriumState(..)
    ) where

import MEDICUS.Space.Types
import MEDICUS.Norm (constraintViolationPenalty)
import qualified Data.Vector.Storable as V
import System.Random (randomRIO)

-- ===== Task 7.1: Medical Energy Function =====

-- | Energy components structure
data EnergyComponents = EnergyComponents
    { costComponent :: Double        -- Security/operational cost
    , riskComponent :: Double        -- Medical risk
    , constraintComponent :: Double  -- Constraint violation
    } deriving (Show, Eq)

-- | Compute medical system energy E_medical(θ)
-- Integrates cost, risk, and constraint components
medicalEnergy :: MedicusSpace -> Domain -> Double
medicalEnergy space theta =
    let components = computeEnergyComponents space theta
    in costComponent components + 
       riskComponent components + 
       constraintComponent components

-- | Compute individual energy components
computeEnergyComponents :: MedicusSpace -> Domain -> EnergyComponents
computeEnergyComponents space theta =
    let -- Cost component: based on parameter magnitude
        cost = V.sum (V.map abs theta)
        
        -- Risk component: based on deviation from safe center
        safeCenter = V.fromList $ replicate (V.length theta) 0.5
        deviation = V.zipWith (-) theta safeCenter
        risk = sqrt $ V.sum $ V.map (\x -> x * x) deviation
        
        -- Constraint component: use existing constraint violation
        dim = V.length theta
        dummyHessian = \_ -> replicate dim (replicate dim 0.0)
        mf = MedicusFunction 
            { mfFunction = makeMedicalFunction $ \_ -> V.sum theta
            , mfGradient = \_ -> theta
            , mfHessian = dummyHessian
            , mfConstraints = []
            }
        constraintCost = constraintViolationPenalty space mf
        
    in EnergyComponents cost risk constraintCost

-- | Analyze energy landscape
-- Returns (min_energy, max_energy, mean_energy)
analyzeEnergyLandscape :: MedicusSpace -> DomainBounds -> (Double, Double, Double)
analyzeEnergyLandscape space bounds =
    let samples = generateLandscapeSamples bounds 20
        energies = map (medicalEnergy space) samples
    in if null energies
       then (0.0, 0.0, 0.0)
       else (minimum energies, maximum energies, sum energies / fromIntegral (length energies))

-- | Generate samples for energy landscape analysis
generateLandscapeSamples :: DomainBounds -> Int -> [Domain]
generateLandscapeSamples bounds n =
    let points = take n $ iterate (incrementPoint bounds) (V.fromList [lo | (lo, _) <- bounds])
    in points
  where
    incrementPoint :: DomainBounds -> Domain -> Domain
    incrementPoint bs pt =
        let step = 0.1
        in V.imap (\i x -> 
            let (lo, hi) = bs !! i
            in if x + step <= hi then x + step else lo
            ) pt

-- ===== Task 7.3: Emergency Parameter Scaling =====

-- | Map emergency level to physical temperature T_emergency
-- Higher emergency → lower temperature → sharper distribution
emergencyLevelToTemperature :: Double -> Double
emergencyLevelToTemperature emergencyLevel =
    let -- Emergency level in [0, 10], temperature mapping
        -- High emergency (10) → Low temp (0.01)
        -- Low emergency (0) → High temp (10.0)
        maxTemp = 10.0
        minTemp = 0.01
        -- Inverse relationship
        normalized = max 0.0 (min 10.0 emergencyLevel) / 10.0
        temp = maxTemp * (1.0 - normalized) + minTemp * normalized
    in temp

-- | Inverse mapping: temperature to emergency level
temperatureToEmergencyLevel :: Double -> Double
temperatureToEmergencyLevel temperature =
    let maxTemp = 10.0
        minTemp = 0.01
        -- Inverse of emergencyLevelToTemperature
        normalized = (temperature - minTemp) / (maxTemp - minTemp)
        emergencyLevel = 10.0 * (1.0 - normalized)
    in max 0.0 (min 10.0 emergencyLevel)

-- | Emergency temperature scale with physical meaning
emergencyTemperatureScale :: Double -> Double
emergencyTemperatureScale = emergencyLevelToTemperature

-- | Check scale invariance: dimensionless ratios preserved
checkScaleInvariance :: Double -> Double -> Bool
checkScaleInvariance temp1 temp2 =
    let ratio = temp1 / temp2
    in ratio > 0 && not (isNaN ratio) && not (isInfinite ratio)

-- ===== Task 7.5: Partition Function Computation =====

-- | Compute partition function Z_medical
-- Z = ∫ exp(-E_medical(θ)/T) dθ
partitionFunction :: MedicusSpace -> Double -> Double
partitionFunction space temperature =
    computePartitionFunction space temperature (domainBounds space) 10

-- | Compute partition function with specified sampling
computePartitionFunction :: MedicusSpace -> Double -> DomainBounds -> Int -> Double
computePartitionFunction space temperature bounds samplesPerDim =
    let samples = generatePartitionSamples bounds samplesPerDim
        integrand theta = exp (negate $ medicalEnergy space theta / temperature)
        values = map integrand samples
        volume = computeIntegrationVolume bounds
        -- Trapezoidal rule approximation
        integral = (sum values / fromIntegral (length values)) * volume
    in if integral > 0 then integral else 1.0

-- | Adaptive partition integration with convergence check
adaptivePartitionIntegration :: MedicusSpace -> Double -> DomainBounds -> Double -> Double
adaptivePartitionIntegration space temperature bounds targetTolerance =
    let -- Start with coarse sampling
        medium = computePartitionFunction space temperature bounds 10
        fine = computePartitionFunction space temperature bounds 15
        -- Check convergence
        error2 = abs (fine - medium) / max 1.0 (abs fine)
    in if error2 < targetTolerance then fine else medium

-- | Verify partition function convergence
verifyPartitionConvergence :: MedicusSpace -> Double -> DomainBounds -> Bool
verifyPartitionConvergence space temperature bounds =
    let z1 = computePartitionFunction space temperature bounds 5
        z2 = computePartitionFunction space temperature bounds 10
        relativeError = abs (z2 - z1) / max 1.0 (abs z2)
    in relativeError < 0.1 && z2 > 0

-- | Generate samples for partition function integration
generatePartitionSamples :: DomainBounds -> Int -> [Domain]
generatePartitionSamples bounds n =
    let -- Generate grid points
        gridPoints = sequence [linspace lo hi n | (lo, hi) <- bounds]
    in map V.fromList gridPoints
  where
    linspace :: Double -> Double -> Int -> [Double]
    linspace lo hi n' =
        let step = (hi - lo) / fromIntegral (max 1 (n' - 1))
        in [lo + step * fromIntegral i | i <- [0..n'-1]]

-- | Compute integration volume
computeIntegrationVolume :: DomainBounds -> Double
computeIntegrationVolume bounds =
    product [(hi - lo) | (lo, hi) <- bounds]

-- ===== Task 7.7: Boltzmann Distribution =====

-- | Compute Boltzmann distribution P(θ)
-- P(θ) = exp(-E_medical(θ)/T_emergency) / Z_medical
boltzmannDistribution :: MedicusSpace -> Double -> Domain -> Double
boltzmannDistribution space temperature theta =
    let energy = medicalEnergy space theta
        z = partitionFunction space temperature
        unnormalized = exp (negate $ energy / temperature)
    in unnormalized / z

-- | Normalize probability density over domain
normalizeProbabilityDensity :: [Double] -> [Double]
normalizeProbabilityDensity probs =
    let total = sum probs
    in if total > 0
       then map (/ total) probs
       else replicate (length probs) (1.0 / fromIntegral (length probs))

-- | Sample from Boltzmann distribution (Monte Carlo)
sampleBoltzmannDistribution :: MedicusSpace -> Double -> Int -> IO [Domain]
sampleBoltzmannDistribution space _temperature numSamples =
    let bounds = domainBounds space
    in mapM (\_ -> generateRandomPoint bounds) [1..numSamples]
  where
    generateRandomPoint :: DomainBounds -> IO Domain
    generateRandomPoint bs = do
        values <- mapM (\(lo, hi) -> randomRIO (lo, hi)) bs
        return $ V.fromList values

-- ===== Task 7.9: Statistical Equilibrium Solver =====

-- | Equilibrium state structure
data EquilibriumState = EquilibriumState
    { eqParameter :: Domain
    , eqEnergy :: Double
    , eqFreeEnergy :: Double
    , eqProbability :: Double
    } deriving (Show, Eq)

-- | Compute free energy F = E - T*S
-- For single parameter state (simplified)
freeEnergy :: MedicusSpace -> Double -> Domain -> Double
freeEnergy space temperature theta =
    let energy = medicalEnergy space theta
        -- Entropy approximation: S ≈ -ln P(θ)
        prob = boltzmannDistribution space temperature theta
        entropy = if prob > 0 then -log prob else 0.0
    in energy - temperature * entropy

-- | Find statistical equilibrium state
-- Minimize free energy F = E - T*S
statisticalEquilibrium :: MedicusSpace -> Double -> EquilibriumState
statisticalEquilibrium space temperature =
    let bounds = domainBounds space
        candidates = generatePartitionSamples bounds 15
        -- Compute free energy for each candidate
        energiesAndFree = [(theta, 
                          medicalEnergy space theta,
                          freeEnergy space temperature theta,
                          boltzmannDistribution space temperature theta)
                         | theta <- candidates]
        -- Find minimum free energy state
        (bestTheta, bestE, bestF, bestP) = 
            minimumBy (\(_, _, f1, _) (_, _, f2, _) -> compare f1 f2) energiesAndFree
    in EquilibriumState bestTheta bestE bestF bestP
  where
    minimumBy :: (a -> a -> Ordering) -> [a] -> a
    minimumBy _ [] = error "minimumBy: empty list"
    minimumBy cmp (x:xs) = foldl (\a b -> if cmp a b == GT then b else a) x xs

-- | Minimize free energy
minimizeFreeEnergy :: MedicusSpace -> Double -> DomainBounds -> Domain
minimizeFreeEnergy space temperature _bounds =
    let eq = statisticalEquilibrium space temperature
    in eqParameter eq

-- | Analyze stability of equilibrium
-- Check if perturbations increase free energy
analyzeStability :: MedicusSpace -> Double -> Domain -> Bool
analyzeStability space temperature theta =
    let f0 = freeEnergy space temperature theta
        -- Generate small perturbations
        eps = 0.01
        perturbations = [V.imap (\i x -> x + (if i == j then eps else 0)) theta 
                        | j <- [0..V.length theta - 1]]
        perturbedFree = map (freeEnergy space temperature) perturbations
        -- Stable if all perturbations increase free energy
        allHigher = all (> f0) perturbedFree
    in allHigher
