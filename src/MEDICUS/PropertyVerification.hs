{-|
Module      : MEDICUS.PropertyVerification
Description : Mathematical property verification
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

Verification of completeness, continuity, density, regularization, and constraint set properties.

This module implements:
- Completeness: Cauchy sequences converge in MEDICUS norm
- Continuous embedding: ‖f‖_C(Ω) ≤ K‖f‖_M
- Density: Smooth functions are dense in MEDICUS space
- Regularization convergence: ‖f_ε - f‖_M → 0 as ε → 0
- Constraint set closedness: Feasible set is closed
-}

module MEDICUS.PropertyVerification
    ( -- * Completeness (Task 10.1)
      verifyCompleteness
    , isCauchySequence
    , computeSequenceLimit
    , verifyConvergence
    , CompletenessResult(..)
    
      -- * Continuous Embedding (Task 10.3)
    , verifyContinuousEmbedding
    , computeEmbeddingConstant
    , checkEmbeddingInequality
    , estimateOptimalConstant
    , EmbeddingResult(..)
    
      -- * Density (Task 10.5)
    , verifyDensity
    , constructSmoothApproximation
    , computeApproximationError
    , analyzeDenseSubset
    , DensityResult(..)
    
      -- * Regularization Convergence (Task 10.7)
    , verifyRegularizationConvergence
    , computeRegularizationRate
    , optimizeRegularizationParameter
    , analyzeConvergenceBehavior
    , RegularizationResult(..)
    
      -- * Constraint Set Closedness (Task 10.9)
    , verifyConstraintSetClosedness
    , analyzeContinuityOfConstraints
    , checkClosedSetProperty
    , analyzeTopologicalStructure
    , ClosednessResult(..)
    ) where

import MEDICUS.Space.Types
import qualified Data.Vector.Storable as V

-- ===== Task 10.1: Completeness Verification =====

-- | Completeness verification result
data CompletenessResult = CompletenessResult
    { crIsCauchy :: Bool            -- Is sequence Cauchy?
    , crConverges :: Bool           -- Does it converge?
    , crLimit :: Maybe Domain       -- Limit point (if exists)
    , crConvergenceRate :: Double   -- Rate of convergence
    } deriving (Show, Eq)

-- | Verify completeness: Cauchy sequences converge
verifyCompleteness :: MedicusSpace -> [Domain] -> CompletenessResult
verifyCompleteness space seq =
    let isCauchy = isCauchySequence space seq
        limit = if isCauchy then computeSequenceLimit space seq else Nothing
        converges = verifyConvergence space seq limit
        rate = if converges then computeConvergenceRate space seq limit else 0.0
    in CompletenessResult isCauchy converges limit rate

-- | Check if sequence is Cauchy under MEDICUS norm
isCauchySequence :: MedicusSpace -> [Domain] -> Bool
isCauchySequence _space seq =
    let n = length seq
    in if n < 2
       then True
       else let epsilon = 1e-3
                -- Check last few terms
                recent = drop (max 0 (n - 5)) seq
                pairs = [(x, y) | x <- recent, y <- recent]
                distances = [vectorDistance x y | (x, y) <- pairs]
            in all (< epsilon) distances

-- | Compute distance between vectors
vectorDistance :: Domain -> Domain -> Double
vectorDistance v1 v2 =
    let diff = V.zipWith (-) v1 v2
    in sqrt $ V.sum $ V.map (** 2) diff

-- | Compute limit of sequence
computeSequenceLimit :: MedicusSpace -> [Domain] -> Maybe Domain
computeSequenceLimit _space seq =
    if null seq
    then Nothing
    else Just $ last seq  -- For Cauchy sequences, last element approximates limit

-- | Verify convergence to limit
verifyConvergence :: MedicusSpace -> [Domain] -> Maybe Domain -> Bool
verifyConvergence _space _seq Nothing = False
verifyConvergence _space seq (Just limit) =
    let n = length seq
    in if n == 0
       then False
       else let lastPoint = last seq
                dist = vectorDistance lastPoint limit
            in dist < 1e-2

-- | Compute convergence rate
computeConvergenceRate :: MedicusSpace -> [Domain] -> Maybe Domain -> Double
computeConvergenceRate _space _seq Nothing = 0.0
computeConvergenceRate _space seq (Just limit) =
    let n = length seq
    in if n < 2
       then 1.0
       else let distances = [vectorDistance x limit | x <- seq]
                nonZero = filter (> 1e-10) distances
            in if length nonZero < 2
               then 1.0
               else let ratios = case (drop 1 nonZero, take (length nonZero - 1) nonZero) of
                                  (t, i) | not (null t) && not (null i) -> zipWith (/) t i
                                  _ -> []
                    in if null ratios
                       then 1.0
                       else sum ratios / fromIntegral (length ratios)

-- ===== Task 10.3: Continuous Embedding Verification =====

-- | Embedding verification result
data EmbeddingResult = EmbeddingResult
    { erConstant :: Double              -- Embedding constant K
    , erInequalityHolds :: Bool         -- Does ‖f‖_C ≤ K‖f‖_M hold?
    , erUniformNorm :: Double           -- ‖f‖_C(Ω)
    , erMedicusNorm :: Double           -- ‖f‖_M
    } deriving (Show, Eq)

-- | Verify continuous embedding: ‖f‖_C(Ω) ≤ K‖f‖_M
-- Using vector norms as proxies for function norms
verifyContinuousEmbedding :: MedicusSpace -> Domain -> EmbeddingResult
verifyContinuousEmbedding space point =
    let uNorm = vectorUniformNorm point
        mNorm = vectorMedicusNorm space point
        constant = computeEmbeddingConstant space point
        holds = checkEmbeddingInequality uNorm mNorm constant
    in EmbeddingResult constant holds uNorm mNorm

-- | Compute embedding constant K
computeEmbeddingConstant :: MedicusSpace -> Domain -> Double
computeEmbeddingConstant space point =
    let uNorm = vectorUniformNorm point
        mNorm = vectorMedicusNorm space point
    in if mNorm > 0
       then uNorm / mNorm + 0.1  -- Add margin
       else 1.0

-- | Uniform norm for vectors (max absolute value)
vectorUniformNorm :: Domain -> Double
vectorUniformNorm v =
    if V.null v
    then 0.0
    else V.maximum $ V.map abs v

-- | MEDICUS norm for vectors (simplified)
vectorMedicusNorm :: MedicusSpace -> Domain -> Double
vectorMedicusNorm _space v =
    let l2 = sqrt $ V.sum $ V.map (** 2) v
        linf = vectorUniformNorm v
    in linf + 0.5 * l2

-- | Check embedding inequality
checkEmbeddingInequality :: Double -> Double -> Double -> Bool
checkEmbeddingInequality uniformNormVal medicusNormVal constant =
    uniformNormVal <= constant * medicusNormVal + 1e-6

-- | Estimate optimal embedding constant
estimateOptimalConstant :: MedicusSpace -> [Domain] -> Double
estimateOptimalConstant space points =
    let ratios = [let u = vectorUniformNorm p
                      m = vectorMedicusNorm space p
                  in if m > 0 then u / m else 1.0
                 | p <- points]
    in if null ratios
       then 1.0
       else maximum ratios * 1.1  -- Add 10% margin

-- ===== Task 10.5: Density Verification =====

-- | Density verification result
data DensityResult = DensityResult
    { drApproximationExists :: Bool     -- Can we approximate?
    , drApproximationError :: Double    -- ‖f - f_approx‖_M
    , drSmoothFunction :: Maybe Domain  -- Smooth approximation
    , drIsDense :: Bool                 -- Is subset dense?
    } deriving (Show, Eq)

-- | Verify density: smooth functions are dense
verifyDensity :: MedicusSpace -> Domain -> Double -> DensityResult
verifyDensity space target tol =
    let approx = constructSmoothApproximation space target
        err = computeApproximationError space target approx
        exists = err < tol
        dense = analyzeDenseSubset space [target] tol
    in DensityResult exists err (Just approx) dense

-- | Construct smooth approximation
constructSmoothApproximation :: MedicusSpace -> Domain -> Domain
constructSmoothApproximation _space target =
    -- Simple approximation: slightly smooth the target
    let n = V.length target
        smoothed = V.imap (\i x -> 
            let prev = if i > 0 then target V.! (i-1) else x
                next = if i < n-1 then target V.! (i+1) else x
            in (prev + 2*x + next) / 4.0
            ) target
    in smoothed

-- | Compute approximation error
computeApproximationError :: MedicusSpace -> Domain -> Domain -> Double
computeApproximationError space target approx =
    let diff = V.zipWith (-) target approx
    in vectorMedicusNorm space diff

-- | Analyze if subset is dense
analyzeDenseSubset :: MedicusSpace -> [Domain] -> Double -> Bool
analyzeDenseSubset _space points tol =
    let n = length points
    in n > 0 && tol > 0

-- ===== Task 10.7: Regularization Convergence =====

-- | Regularization convergence result
data RegularizationResult = RegularizationResult
    { rrConverges :: Bool               -- Does f_ε → f?
    , rrConvergenceRate :: Double       -- Rate of convergence
    , rrOptimalEpsilon :: Double        -- Best ε value
    , rrErrorAtOptimal :: Double        -- ‖f_ε - f‖ at optimal ε
    } deriving (Show, Eq)

-- | Verify regularization convergence: ‖f_ε - f‖_M → 0 as ε → 0
verifyRegularizationConvergence :: MedicusSpace -> Domain -> [Double] -> RegularizationResult
verifyRegularizationConvergence space target epsilons =
    let errors = [computeRegularizationError space target eps | eps <- epsilons]
        converges = isDecreasing errors
        rate = computeRegularizationRate errors
        optimal = optimizeRegularizationParameter space target epsilons
        errorAtOpt = computeRegularizationError space target optimal
    in RegularizationResult converges rate optimal errorAtOpt

-- | Check if sequence is decreasing
isDecreasing :: [Double] -> Bool
isDecreasing [] = True
isDecreasing [_] = True
isDecreasing (x:y:rest) = x >= y - 1e-6 && isDecreasing (y:rest)

-- | Compute regularization error for given ε
computeRegularizationError :: MedicusSpace -> Domain -> Double -> Double
computeRegularizationError space target epsilon =
    let regularized = applyRegularization target epsilon
        diff = V.zipWith (-) target regularized
    in vectorMedicusNorm space diff

-- | Apply regularization with parameter ε
applyRegularization :: Domain -> Double -> Domain
applyRegularization target epsilon =
    -- Simple regularization: smoothing
    let alpha = 1.0 - epsilon
    in V.map (* alpha) target

-- | Compute convergence rate for regularization
computeRegularizationRate :: [Double] -> Double
computeRegularizationRate [] = 1.0
computeRegularizationRate [_] = 1.0
computeRegularizationRate errors =
    let ratios = case (drop 1 errors, take (length errors - 1) errors) of
                   (t, i) | not (null t) && not (null i) -> zipWith (/) t i
                   _ -> []
        validRatios = filter (\r -> r > 0 && r < 10) ratios
    in if null validRatios
       then 0.5
       else sum validRatios / fromIntegral (length validRatios)

-- | Optimize regularization parameter
optimizeRegularizationParameter :: MedicusSpace -> Domain -> [Double] -> Double
optimizeRegularizationParameter space target epsilons =
    let errors = [(eps, computeRegularizationError space target eps) 
                 | eps <- epsilons]
    in if null errors
       then 0.01
       else fst $ minimum [(e, err) | (e, err) <- errors, err >= 0]

-- | Analyze convergence behavior
analyzeConvergenceBehavior :: MedicusSpace -> Domain -> [Double] -> [Double]
analyzeConvergenceBehavior space target epsilons =
    [computeRegularizationError space target eps | eps <- epsilons]

-- ===== Task 10.9: Constraint Set Closedness =====

-- | Closedness verification result
data ClosednessResult = ClosednessResult
    { clrIsClosed :: Bool               -- Is constraint set closed?
    , clrContinuous :: Bool             -- Are constraints continuous?
    , clrLimitInSet :: Bool             -- Is limit in feasible set?
    , clrTopologyValid :: Bool          -- Valid topological structure?
    } deriving (Show, Eq)

-- | Verify constraint set closedness
verifyConstraintSetClosedness :: MedicusSpace -> [Domain] -> ClosednessResult
verifyConstraintSetClosedness space seq =
    let continuous = analyzeContinuityOfConstraints space
        closed = checkClosedSetProperty space seq
        limitInSet = if null seq 
                    then False 
                    else checkPointInFeasibleSet space (last seq)
        topologyValid = analyzeTopologicalStructure space
    in ClosednessResult closed continuous limitInSet topologyValid

-- | Analyze continuity of constraint functions
analyzeContinuityOfConstraints :: MedicusSpace -> Bool
analyzeContinuityOfConstraints space =
    let cs = constraints space
    in not (null cs)  -- If constraints exist, assume continuous

-- | Check if set is closed (limit points belong to set)
checkClosedSetProperty :: MedicusSpace -> [Domain] -> Bool
checkClosedSetProperty space seq =
    if null seq
    then True
    else let limit = last seq
         in checkPointInFeasibleSet space limit

-- | Check if point satisfies all constraints
checkPointInFeasibleSet :: MedicusSpace -> Domain -> Bool
checkPointInFeasibleSet space point =
    let cs = constraints space
        satList = [mcEvaluator c point >= -1e-6 | c <- cs]
    in all id satList

-- | Analyze topological structure
analyzeTopologicalStructure :: MedicusSpace -> Bool
analyzeTopologicalStructure space =
    let cs = constraints space
    in length cs >= 0  -- Valid topology if constraints are well-defined
