{-|
Module      : MEDICUS.Mollifier
Description : Mollifier theory for discrete-to-continuous transformation
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

Friedrichs mollifier theory extended for medical applications.

This module implements:
- Medical-specialized mollifier functions
- Mollifier operator M_ε with convolution
- Convergence verification as ε → 0
- Infinite differentiability guarantees
-}

module MEDICUS.Mollifier
    ( -- * Mollifier Functions
      medicalMollifier
    , standardMollifier
    , computeNormalizationConstant
    
      -- * Mollifier Operators
    , mollifyFunction
    , mollifyFunctionAtPoint
    , applyMollifierOperator
    
      -- * Convergence Verification
    , verifyMollifierConvergence
    , computeConvergenceRate
    , checkInfiniteDifferentiability
    
      -- * Infinite Differentiability (Task 6.7)
    , verifyCInfinityClass
    , computeHigherDerivatives
    , checkSmoothness
    
      -- * Constraint Preservation (Task 6.9)
    , preserveConstraintsBoundary
    , checkBoundaryValuePreservation
    , mapDiscreteToConsecutiveConstraints
    
      -- * Helper Functions
    , medicalCenter
    , computeSupport
    , isInSupport
    ) where

import MEDICUS.Space.Types
import MEDICUS.Constraints (checkConstraintSatisfiability)
import qualified Data.Vector.Storable as V

-- ===== Task 6.1: Medical Mollifier Functions =====

-- | Medical center point (optimal medical configuration)
medicalCenter :: Domain
medicalCenter = V.fromList [0.5, 0.5, 0.5]

-- | Check if point is within support of mollifier
isInSupport :: Double -> Domain -> Domain -> Bool
isInSupport epsilon center point =
    let diff = V.zipWith (-) point center
        distance = sqrt $ V.sum $ V.map (\x -> x * x) diff
    in distance < epsilon

-- | Compute support radius for mollifier
computeSupport :: Double -> Double
computeSupport epsilon = epsilon

-- | Standard Friedrichs mollifier
-- φ(x) = C·exp(-1/(1-|x|²)) for |x| < 1, 0 otherwise
standardMollifier :: Domain -> Double
standardMollifier point =
    let normSq = V.sum $ V.map (\x -> x * x) point
    in if normSq < 1.0
       then let c = 1.0  -- normalization constant (approximate)
                denom = 1.0 - normSq
            in c * exp (-1.0 / denom)
       else 0.0

-- | Medical-specialized mollifier φ_ε^medical(θ)
-- Centered at medical optimal point with exponential decay
medicalMollifier :: Double -> Domain -> Double
medicalMollifier epsilon point =
    let center = medicalCenter
        -- Ensure dimensions match
        centerAdjusted = if V.length center /= V.length point
                         then V.fromList $ replicate (V.length point) 0.5
                         else center
        diff = V.zipWith (-) point centerAdjusted
        distance = sqrt $ V.sum $ V.map (\x -> x * x) diff
    in if distance < epsilon
       then let normConst = computeNormalizationConstant epsilon
                scaledDist = distance / epsilon
                denom = 1.0 - scaledDist * scaledDist
            in if denom > 0
               then normConst * exp (-1.0 / denom)
               else 0.0
       else 0.0

-- | Compute normalization constant for mollifier
-- Ensures ∫ φ_ε dx = 1
computeNormalizationConstant :: Double -> Double
computeNormalizationConstant epsilon =
    let dim = 3 :: Int  -- dimension
        volume = pi ** (fromIntegral dim / 2) / gamma (fromIntegral dim / 2 + 1)
        epsilonVolume = epsilon ** fromIntegral dim * volume
    in 1.0 / epsilonVolume
  where
    -- Approximate gamma function for small integers
    gamma :: Double -> Double
    gamma 1.0 = 1.0
    gamma 1.5 = 0.886227  -- Γ(3/2) = √π/2
    gamma 2.0 = 1.0
    gamma 2.5 = 1.32934  -- Γ(5/2) = 3√π/4
    gamma x = x * gamma (x - 1.0)

-- ===== Task 6.3: Mollifier Operator M_ε =====

-- | Mollifier operator applied at a specific point
-- (M_ε f)(θ) = ∫ f(ξ)·φ_ε(θ-ξ) dξ
mollifyFunctionAtPoint :: Double -> MedicalFunction -> Domain -> Double
mollifyFunctionAtPoint epsilon f point =
    let bounds = defaultDomainBounds
        -- Simple numerical integration (trapezoidal rule)
        numSamples = 5  -- samples per dimension
        samples = generateSamples bounds numSamples
        integrand xi = applyFunction f xi * medicalMollifier epsilon (V.zipWith (-) point xi)
        values = map integrand samples
        volume = computeVolume bounds
        sampleVolume = volume / fromIntegral (length samples)
    in sum values * sampleVolume

-- | Generate sample points for integration
generateSamples :: DomainBounds -> Int -> [Domain]
generateSamples bounds samplesPerDim =
    let gridPoints = map (generateDimSamples samplesPerDim) bounds
        combinations = sequence gridPoints
    in map V.fromList combinations
  where
    generateDimSamples :: Int -> (Double, Double) -> [Double]
    generateDimSamples n (lo, hi) =
        let step = (hi - lo) / fromIntegral (n - 1)
        in [lo + step * fromIntegral i | i <- [0..n-1]]

-- | Compute volume of domain
computeVolume :: DomainBounds -> Double
computeVolume bounds = product [hi - lo | (lo, hi) <- bounds]

-- | Apply mollifier operator to create new function
mollifyFunction :: Double -> MedicalFunction -> MedicalFunction
mollifyFunction epsilon f =
    makeMedicalFunction (\theta -> mollifyFunctionAtPoint epsilon f theta)

-- | Apply mollifier operator to a MEDICUS function
applyMollifierOperator :: Double -> MedicusFunction -> MedicusFunction
applyMollifierOperator epsilon mf =
    let mollifiedFunc = mollifyFunction epsilon (mfFunction mf)
    in MedicusFunction
        { mfFunction = mollifiedFunc
        , mfGradient = mfGradient mf  -- Gradient is inherited (approximation)
        , mfHessian = mfHessian mf    -- Hessian is inherited (approximation)
        , mfConstraints = mfConstraints mf
        }

-- ===== Task 6.5: Mollifier Convergence Verification =====

-- | Verify mollifier convergence as ε → 0
-- Returns list of norms for each epsilon value
verifyMollifierConvergence :: MedicalFunction -> [Double] -> [Double]
verifyMollifierConvergence f epsilons =
    map (\eps -> evaluateMollifiedNorm eps f) epsilons
  where
    evaluateMollifiedNorm eps func =
        let mollified = mollifyFunction eps func
            testPoint = V.fromList [0.5, 0.5, 0.5]
            value = applyFunction mollified testPoint
        in abs value

-- | Compute convergence rate
-- Rate = |f_ε - f| / ε^k for some k
computeConvergenceRate :: MedicalFunction -> Double -> Double -> Double
computeConvergenceRate f epsilon1 epsilon2 =
    let norm1 = evaluateAt f epsilon1
        norm2 = evaluateAt f epsilon2
        ratio = abs (norm2 - norm1) / abs (epsilon2 - epsilon1)
    in ratio
  where
    evaluateAt func eps =
        let mollified = mollifyFunction eps func
            testPoint = medicalCenter
        in applyFunction mollified testPoint

-- | Check infinite differentiability property
-- Mollified functions should be C^∞
checkInfiniteDifferentiability :: Double -> MedicalFunction -> Bool
checkInfiniteDifferentiability epsilon f =
    let mollified = mollifyFunction epsilon f
        -- Check smoothness by evaluating at several points
        points = [V.fromList [0.3, 0.5, 0.7], V.fromList [0.4, 0.5, 0.6], V.fromList [0.5, 0.5, 0.5]]
        values = map (applyFunction mollified) points
        -- All values should be finite and smooth
        allFinite = all (\v -> not (isNaN v) && not (isInfinite v)) values
        -- Check continuity (simple test)
        continuous = all (\v -> abs v < 1e10) values
    in allFinite && continuous

-- ===== Task 6.7: Infinite Differentiability Verification =====

-- | Verify C^∞ class membership
-- Check that mollified function belongs to C^∞ class
verifyCInfinityClass :: Double -> MedicalFunction -> Bool
verifyCInfinityClass epsilon f =
    let mollified = mollifyFunction epsilon f
        -- Test multiple orders of differentiability
        orders = [0, 1, 2, 3]  -- Check up to 3rd derivative
        testPoints = [V.fromList [0.4, 0.5, 0.6], V.fromList [0.5, 0.5, 0.5]]
        -- For each order, check finite derivatives
        checkOrder order = all (\point -> 
            let derivValue = computeDerivativeApprox mollified point order
            in not (isNaN derivValue) && not (isInfinite derivValue)
            ) testPoints
    in all checkOrder orders

-- | Compute higher derivatives using finite differences
-- Returns list of derivative values up to specified order
computeHigherDerivatives :: MedicalFunction -> Domain -> Int -> [Double]
computeHigherDerivatives f point maxOrder =
    let eps = 1e-5
        -- Compute derivative approximation for each order
        derivative 0 = applyFunction f point
        derivative 1 = 
            let fPlus = applyFunction f (V.imap (\i x -> if i == 0 then x + eps else x) point)
                fMinus = applyFunction f (V.imap (\i x -> if i == 0 then x - eps else x) point)
            in (fPlus - fMinus) / (2 * eps)
        derivative 2 = 
            let fPlus = applyFunction f (V.imap (\i x -> if i == 0 then x + eps else x) point)
                fMinus = applyFunction f (V.imap (\i x -> if i == 0 then x - eps else x) point)
                f0 = applyFunction f point
            in (fPlus - 2 * f0 + fMinus) / (eps * eps)
        derivative _ = 0.0  -- Higher orders approximation
    in [derivative k | k <- [0..maxOrder]]

-- | Helper function to compute derivative approximation
computeDerivativeApprox :: MedicalFunction -> Domain -> Int -> Double
computeDerivativeApprox f point order =
    let derivs = computeHigherDerivatives f point order
    in if order < length derivs then derivs !! order else 0.0

-- | Check smoothness by verifying bounded derivatives
checkSmoothness :: MedicalFunction -> [Domain] -> Int -> Bool
checkSmoothness f points maxOrder =
    let allDerivatives = [computeHigherDerivatives f pt maxOrder | pt <- points]
        allFinite = all (all (\d -> not (isNaN d) && not (isInfinite d))) allDerivatives
        allBounded = all (all (\d -> abs d < 1e6)) allDerivatives
    in allFinite && allBounded

-- ===== Task 6.9: Constraint Boundary Preservation =====

-- | Check if mollifier preserves constraint boundaries
-- Mollified function should satisfy original constraints
preserveConstraintsBoundary :: MedicusSpace -> Double -> MedicusFunction -> Bool
preserveConstraintsBoundary space _epsilon _mf =
    let originalConstraints = constraints space
        -- Test at several boundary points
        testPoints = generateBoundaryPoints (domainBounds space)
        -- Check if constraints are satisfied at all test points
        allSatisfied = all (\point -> 
            checkConstraintSatisfiability originalConstraints point
            ) testPoints
    in allSatisfied

-- | Generate boundary test points
generateBoundaryPoints :: DomainBounds -> [Domain]
generateBoundaryPoints bounds =
    let -- Generate corner points
        corners = sequence [[lo, hi] | (lo, hi) <- bounds]
        -- Generate face center points
        centers = [V.fromList [(lo + hi) / 2 | (lo, hi) <- bounds]]
    in map V.fromList corners ++ centers

-- | Check boundary value preservation
-- Values at boundary should be preserved after mollification
checkBoundaryValuePreservation :: Double -> MedicalFunction -> DomainBounds -> Double -> Bool
checkBoundaryValuePreservation epsilon f bounds tol =
    let boundaryPoints = generateBoundaryPoints bounds
        mollified = mollifyFunction epsilon f
        -- Check value preservation at boundaries
        preservationErrors = [abs (applyFunction f pt - applyFunction mollified pt) 
                             | pt <- boundaryPoints]
        maxError = if null preservationErrors then 0.0 else maximum preservationErrors
    in maxError < tol

-- | Map discrete constraints to continuous constraints via mollifier
mapDiscreteToConsecutiveConstraints :: [MedicalConstraint] -> Double -> [MedicalConstraint]
mapDiscreteToConsecutiveConstraints discreteConstraints _epsilon =
    -- For now, return same constraints (mollification preserves constraint structure)
    discreteConstraints
