{-|
Module      : MEDICUS.EntropyManagement
Description : Entropy management and thermodynamic laws
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

Thermodynamic approach to personnel skill management and security entropy.

This module implements:
- Medical security entropy S_security = -Σ pᵢ ln(pᵢ)
- Entropy increase verification (Second Law of Thermodynamics)
- First Law: ΔU_security = Q_education - W_operational
- Education investment quantification
- Operational cost evaluation
-}

module MEDICUS.EntropyManagement
    ( -- * Security Entropy (Task 9.1)
      securityEntropy
    , computeDiscreteEntropy
    , computeContinuousEntropy
    , analyzeSecurityDistribution
    , SecurityDistribution(..)
    
      -- * Entropy Increase (Task 9.3)
    , entropyIncrease
    , verifyEntropyIncreaseRate
    , modelNaturalSkillVariation
    , computeEntropyRate
    
      -- * First Law of Thermodynamics (Task 9.5)
    , firstLawEnergy
    , computeInternalEnergyChange
    , verifyEnergyConservation
    , EnergyBalance(..)
    
      -- * Education Investment (Task 9.7)
    , educationEnergy
    , computeEducationEffect
    , modelEntropyReduction
    , optimizeEducationInvestment
    , EducationInvestment(..)
    
      -- * Operational Cost (Task 9.9)
    , operationalCost
    , measureEnergyConsumption
    , analyzeCostEffectiveness
    , computeEfficiencyMetrics
    , OperationalMetrics(..)
    ) where

-- ===== Task 9.1: Medical Security Entropy =====

-- | Security distribution structure
data SecurityDistribution = SecurityDistribution
    { sdLevels :: [Double]          -- Security levels
    , sdProbabilities :: [Double]   -- Probability distribution
    , sdEntropy :: Double           -- Shannon entropy
    } deriving (Show, Eq)

-- | Compute Shannon entropy S = -Σ pᵢ ln(pᵢ)
securityEntropy :: [Double] -> Double
securityEntropy probabilities =
    computeDiscreteEntropy probabilities

-- | Compute discrete entropy (information entropy)
computeDiscreteEntropy :: [Double] -> Double
computeDiscreteEntropy probs =
    let normalizedProbs = normalizeProbabilities probs
        entropyTerms = [if p > 0 then -p * log p else 0.0 | p <- normalizedProbs]
    in sum entropyTerms

-- | Compute continuous entropy (differential entropy)
-- For continuous probability density
computeContinuousEntropy :: [Double] -> [Double] -> Double
computeContinuousEntropy _values density =
    let normalizedDensity = normalizeProbabilities density
        entropyTerms = [if p > 0 then -p * log (p + 1e-10) else 0.0 
                       | p <- normalizedDensity]
    in sum entropyTerms

-- | Normalize probabilities to sum to 1
normalizeProbabilities :: [Double] -> [Double]
normalizeProbabilities probs =
    let total = sum probs
    in if total > 0
       then map (/ total) probs
       else replicate (length probs) (1.0 / fromIntegral (length probs))

-- | Analyze security level distribution
analyzeSecurityDistribution :: [Double] -> SecurityDistribution
analyzeSecurityDistribution levels =
    let -- Create probability distribution from security levels
        -- Normalize to [0,1] range
        maxLevel = if null levels then 1.0 else maximum levels
        normalized = if maxLevel > 0 
                    then map (/ maxLevel) levels 
                    else levels
        -- Convert to probability distribution
        probs = normalizeProbabilities normalized
        -- Compute entropy
        entropy = computeDiscreteEntropy probs
    in SecurityDistribution levels probs entropy

-- ===== Task 9.3: Entropy Increase Verification =====

-- | Verify entropy increase (Second Law of Thermodynamics)
-- dS/dt ≥ 0
entropyIncrease :: [Double] -> [Double] -> Double
entropyIncrease probsBefore probsAfter =
    let s1 = computeDiscreteEntropy probsBefore
        s2 = computeDiscreteEntropy probsAfter
    in s2 - s1

-- | Verify entropy increase rate is non-negative
verifyEntropyIncreaseRate :: [Double] -> [Double] -> Double -> Bool
verifyEntropyIncreaseRate probsBefore probsAfter dt =
    let ds = entropyIncrease probsBefore probsAfter
        rate = if dt > 0 then ds / dt else 0.0
    in rate >= -1e-10  -- Allow small numerical error

-- | Model natural skill variation (entropy increase mechanism)
-- Skills naturally decay without intervention
modelNaturalSkillVariation :: [Double] -> Double -> [Double]
modelNaturalSkillVariation skills decayRate =
    let -- Apply decay: skills tend toward uniform distribution
        skillsMean = sum skills / fromIntegral (max 1 (length skills))
        decayed = [s * (1 - decayRate) + skillsMean * decayRate | s <- skills]
    in decayed

-- | Compute entropy rate of change dS/dt
computeEntropyRate :: [Double] -> [Double] -> Double -> Double
computeEntropyRate probsBefore probsAfter dt =
    let ds = entropyIncrease probsBefore probsAfter
    in if dt > 0 then ds / dt else 0.0

-- ===== Task 9.5: First Law of Thermodynamics =====

-- | Energy balance structure
data EnergyBalance = EnergyBalance
    { ebInternalEnergyChange :: Double  -- ΔU_security
    , ebEducationEnergy :: Double       -- Q_education (heat in)
    , ebOperationalWork :: Double       -- W_operational (work out)
    , ebConserved :: Bool               -- ΔU = Q - W
    } deriving (Show, Eq)

-- | First Law: ΔU_security = Q_education - W_operational
firstLawEnergy :: Double -> Double -> Double
firstLawEnergy qEducation wOperational =
    qEducation - wOperational

-- | Compute internal energy change
computeInternalEnergyChange :: [Double] -> [Double] -> Double
computeInternalEnergyChange stateBefore stateAfter =
    let energyBefore = sum [s * s | s <- stateBefore]  -- E = Σ sᵢ²
        energyAfter = sum [s * s | s <- stateAfter]
    in energyAfter - energyBefore

-- | Verify energy conservation
verifyEnergyConservation :: Double -> Double -> Double -> EnergyBalance
verifyEnergyConservation deltaU qEducation wOperational =
    let expected = qEducation - wOperational
        conserved = abs (deltaU - expected) < 1e-6
    in EnergyBalance deltaU qEducation wOperational conserved

-- ===== Task 9.7: Education Investment Quantification =====

-- | Education investment structure
data EducationInvestment = EducationInvestment
    { eiInvestmentAmount :: Double      -- Investment (Q_education)
    , eiEntropyReduction :: Double      -- ΔS (negative)
    , eiEffectiveness :: Double         -- Q / |ΔS|
    , eiOptimal :: Bool                 -- Is optimal investment
    } deriving (Show, Eq)

-- | Compute education energy Q_education
-- Energy required to reduce entropy
educationEnergy :: Double -> Double
educationEnergy entropyReduction =
    -- Q proportional to entropy reduction
    -- Negative entropy reduction (increase) → positive energy needed
    abs entropyReduction * 10.0  -- Scaling factor

-- | Compute education effect on entropy
computeEducationEffect :: [Double] -> Double -> [Double]
computeEducationEffect skills investmentAmount =
    let -- Investment increases skills toward higher uniformity
        -- But in a structured way (reduces entropy)
        target = 0.8  -- Target skill level
        improvement = investmentAmount / 100.0
        improved = [s + (target - s) * improvement | s <- skills]
    in improved

-- | Model entropy reduction from education
modelEntropyReduction :: [Double] -> Double -> Double
modelEntropyReduction skillsBefore investment =
    let skillsAfter = computeEducationEffect skillsBefore investment
        sBefore = computeDiscreteEntropy skillsBefore
        sAfter = computeDiscreteEntropy skillsAfter
        reduction = sAfter - sBefore
    in reduction

-- | Optimize education investment
-- Find investment that maximizes effectiveness
optimizeEducationInvestment :: [Double] -> Double -> EducationInvestment
optimizeEducationInvestment skills targetReduction =
    let -- Simple linear model: investment proportional to reduction
        skillsMean = sum skills / fromIntegral (max 1 (length skills))
        investment = educationEnergy targetReduction
        actualReduction = modelEntropyReduction skills investment
        effectiveness = if actualReduction /= 0 
                       then investment / abs actualReduction 
                       else 0.0
        isOptimal = abs (actualReduction - targetReduction) < 0.1 && skillsMean > 0
    in EducationInvestment investment actualReduction effectiveness isOptimal

-- ===== Task 9.9: Operational Cost Evaluation =====

-- | Operational metrics structure
data OperationalMetrics = OperationalMetrics
    { omDailyCost :: Double             -- Daily operational cost
    , omEnergyConsumption :: Double     -- W_operational
    , omEfficiency :: Double            -- Output / Input
    , omCostEffectiveness :: Double     -- Benefit / Cost
    } deriving (Show, Eq)

-- | Compute operational cost W_operational
-- Energy consumed in daily operations
operationalCost :: [Double] -> Double -> Double
operationalCost operations timeUnits =
    let dailyEnergy = sum [abs op | op <- operations]
    in dailyEnergy * timeUnits

-- | Measure energy consumption
measureEnergyConsumption :: [Double] -> Double
measureEnergyConsumption activities =
    sum [abs a * a | a <- activities]  -- Quadratic cost

-- | Analyze cost-effectiveness
analyzeCostEffectiveness :: Double -> Double -> Double
analyzeCostEffectiveness benefit cost =
    if cost > 0 
    then benefit / cost 
    else 0.0

-- | Compute operational efficiency metrics
computeEfficiencyMetrics :: [Double] -> Double -> Double -> OperationalMetrics
computeEfficiencyMetrics activities timeUnits benefit =
    let cost = operationalCost activities timeUnits
        energy = measureEnergyConsumption activities
        efficiency = if energy > 0 then benefit / energy else 0.0
        costEff = analyzeCostEffectiveness benefit cost
    in OperationalMetrics cost energy efficiency costEff
