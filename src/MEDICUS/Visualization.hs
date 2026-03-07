{-|
Module      : MEDICUS.Visualization
Description : Visualization and reporting for MEDICUS Engine
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

Visualization and reporting utilities for MEDICUS computations.

This module provides:
- Function plotting and convergence history (Task 12.5)
- Constraint satisfaction visualization
- Interactive parameter exploration
- Report generation
-}

module MEDICUS.Visualization
    ( -- * Convergence Visualization
      ConvergenceHistory(..)
    , recordIteration
    , plotConvergence
    , analyzeConvergencePattern
    
      -- * Constraint Visualization
    , ConstraintReport(..)
    , visualizeConstraints
    , generateConstraintReport
    , checkConstraintSatisfaction
    
      -- * Function Plotting
    , PlotConfig(..)
    , defaultPlotConfig
    , plotFunction1D
    , plotFunction2D
    , sampleForPlot
    
      -- * Interactive Exploration
    , ExplorationResult(..)
    , exploreParameterSpace
    , sensitivityAnalysis
    , findFeasibleRegion
    
      -- * Report Generation
    , generateFullReport
    , ReportData(..)
    ) where

import MEDICUS.Space.Types
import MEDICUS.Norm
import MEDICUS.Constraints
import qualified Data.Vector.Storable as V

-- ===== Task 12.5: Convergence Visualization =====

-- | History of optimization iterations
data ConvergenceHistory = ConvergenceHistory
    { chIterations :: [Int]
    , chObjectiveValues :: [Double]
    , chNormValues :: [Double]
    , chConstraintViolations :: [Double]
    } deriving (Show, Eq)

-- | Record a single iteration
recordIteration :: ConvergenceHistory -> Int -> Double -> Double -> Double -> ConvergenceHistory
recordIteration hist iter obj norm violation =
    ConvergenceHistory
        { chIterations = chIterations hist ++ [iter]
        , chObjectiveValues = chObjectiveValues hist ++ [obj]
        , chNormValues = chNormValues hist ++ [norm]
        , chConstraintViolations = chConstraintViolations hist ++ [violation]
        }

-- | Create text-based convergence plot
plotConvergence :: ConvergenceHistory -> String
plotConvergence hist =
    let iters = chIterations hist
        objs = chObjectiveValues hist
        norms = chNormValues hist
        violations = chConstraintViolations hist
        rows = zip4List iters objs norms violations
    in unlines
        [ "=== Convergence History ==="
        , "Iteration | Objective  | Norm       | Violations"
        , "----------------------------------------------"
        ] ++ concatMap formatRow rows
  where
    zip4List as bs cs ds = case (as, bs, cs, ds) of
        (a:as', b:bs', c:cs', d:ds') -> (a,b,c,d) : zip4List as' bs' cs' ds'
        _ -> []
    formatRow (i, o, n, v) =
        let pad s w = take w (s ++ repeat ' ')
        in pad (show i) 10 ++ "| " ++
           pad (show o) 11 ++ "| " ++
           pad (show n) 11 ++ "| " ++
           show v ++ "\n"

-- | Analyze convergence pattern
analyzeConvergencePattern :: ConvergenceHistory -> String
analyzeConvergencePattern hist =
    let objs = chObjectiveValues hist
        n = length objs
    in if n < 2
       then "Insufficient data"
       else let improvements = zipWith (-) (init objs) (tail objs)
                avgImprovement = sum improvements / fromIntegral (length improvements)
                isMonotonic = all (>= -1e-10) improvements
            in unlines
                [ "Convergence Pattern Analysis:"
                , "  Total iterations: " ++ show n
                , "  Average improvement: " ++ show avgImprovement
                , "  Monotonic decrease: " ++ show isMonotonic
                , "  Final objective: " ++ show (last objs)
                ]

-- ===== Constraint Visualization =====

-- | Constraint satisfaction report
data ConstraintReport = ConstraintReport
    { crTotalConstraints :: Int
    , crSatisfiedCount :: Int
    , crViolatedCount :: Int
    , crViolationDetails :: [(String, Double)]
    , crSatisfactionRate :: Double
    } deriving (Show, Eq)

-- | Visualize constraint satisfaction
visualizeConstraints :: MedicusSpace -> Domain -> String
visualizeConstraints space point =
    let _cs = constraints space
        report = generateConstraintReport space point
        violationLines = map formatViolation (crViolationDetails report)
    in unlines
        ([ "=== Constraint Satisfaction Report ==="
        , "Total constraints: " ++ show (crTotalConstraints report)
        , "Satisfied: " ++ show (crSatisfiedCount report)
        , "Violated: " ++ show (crViolatedCount report)
        , "Satisfaction rate: " ++ show (crSatisfactionRate report * 100) ++ "%"
        , ""
        , "Violation Details:"
        ] ++ violationLines)
  where
    formatViolation (name, val) =
        "  " ++ name ++ ": " ++ show val

-- | Generate constraint report
generateConstraintReport :: MedicusSpace -> Domain -> ConstraintReport
generateConstraintReport space point =
    let cs = constraints space
        total = length cs
        evaluations = [(mcDescription c, mcEvaluator c point) | c <- cs]
        satisfied = filter (\(_, v) -> v >= 0) evaluations
        violated = filter (\(_, v) -> v < 0) evaluations
        satCount = length satisfied
        violCount = length violated
        satRate = if total > 0 then fromIntegral satCount / fromIntegral total else 1.0
    in ConstraintReport total satCount violCount violated satRate

-- | Check constraint satisfaction status
checkConstraintSatisfaction :: MedicusSpace -> Domain -> Bool
checkConstraintSatisfaction space point =
    let cs = constraints space
        allSatisfied = all (\c -> mcEvaluator c point >= -1e-6) cs
    in allSatisfied

-- ===== Function Plotting =====

-- | Plot configuration
data PlotConfig = PlotConfig
    { pcResolution :: Int       -- Number of sample points
    , pcXMin :: Double
    , pcXMax :: Double
    , pcYMin :: Double
    , pcYMax :: Double
    } deriving (Show, Eq)

-- | Default plot configuration
defaultPlotConfig :: PlotConfig
defaultPlotConfig = PlotConfig
    { pcResolution = 50
    , pcXMin = -10.0
    , pcXMax = 10.0
    , pcYMin = -10.0
    , pcYMax = 10.0
    }

-- | Plot 1D function (text representation)
plotFunction1D :: MedicusFunction -> PlotConfig -> String
plotFunction1D f config =
    let samples = sampleForPlot config
        values = [applyFunction (mfFunction f) (V.singleton x) | x <- samples]
    in unlines
        [ "=== Function Plot (1D) ==="
        , "X Range: [" ++ show (pcXMin config) ++ ", " ++ show (pcXMax config) ++ "]"
        , "Samples: " ++ show (length samples)
        , "Min value: " ++ show (minimum values)
        , "Max value: " ++ show (maximum values)
        ]

-- | Plot 2D function summary
plotFunction2D :: MedicusFunction -> PlotConfig -> String
plotFunction2D f config =
    let resolution = pcResolution config
        xSamples = sampleForPlot config
        ySamples = sampleForPlot config
        points = [(x, y) | x <- xSamples, y <- ySamples]
        values = [applyFunction (mfFunction f) (V.fromList [x, y]) | (x, y) <- points]
    in unlines
        [ "=== Function Plot (2D) ==="
        , "X Range: [" ++ show (pcXMin config) ++ ", " ++ show (pcXMax config) ++ "]"
        , "Y Range: [" ++ show (pcYMin config) ++ ", " ++ show (pcYMax config) ++ "]"
        , "Grid: " ++ show resolution ++ "x" ++ show resolution
        , "Min value: " ++ show (minimum values)
        , "Max value: " ++ show (maximum values)
        , "Mean value: " ++ show (sum values / fromIntegral (length values))
        ]

-- | Generate sample points for plotting
sampleForPlot :: PlotConfig -> [Double]
sampleForPlot config =
    let n = pcResolution config
        xmin = pcXMin config
        xmax = pcXMax config
        step = (xmax - xmin) / fromIntegral (n - 1)
    in [xmin + fromIntegral i * step | i <- [0..n-1]]

-- ===== Interactive Exploration =====

-- | Parameter space exploration result
data ExplorationResult = ExplorationResult
    { erSampledPoints :: [Domain]
    , erObjectiveValues :: [Double]
    , erBestPoint :: Domain
    , erBestValue :: Double
    , erFeasibleCount :: Int
    } deriving (Show, Eq)

-- | Explore parameter space
exploreParameterSpace :: MedicusSpace -> MedicusFunction -> Int -> ExplorationResult
exploreParameterSpace space objective numSamples =
    let bounds = domainBounds space
        _dim = length bounds
        -- Simple grid sampling
        samples = take numSamples $ generateGridPoints bounds 5
        values = [applyFunction (mfFunction objective) p | p <- samples]
        feasible = [p | p <- samples, checkConstraintSatisfaction space p]
        bestIdx = snd $ minimum $ zip values [0..]
        best = samples !! bestIdx
        bestVal = values !! bestIdx
    in ExplorationResult samples values best bestVal (length feasible)

-- | Generate grid points for exploration
generateGridPoints :: DomainBounds -> Int -> [Domain]
generateGridPoints bounds resolution =
    let dim = length bounds
    in case dim of
        1 -> let (lo, hi) = head bounds
                 step = (hi - lo) / fromIntegral (resolution - 1)
             in [V.singleton (lo + fromIntegral i * step) | i <- [0..resolution-1]]
        2 -> let [(lo1, hi1), (lo2, hi2)] = bounds
                 step1 = (hi1 - lo1) / fromIntegral (resolution - 1)
                 step2 = (hi2 - lo2) / fromIntegral (resolution - 1)
             in [V.fromList [lo1 + fromIntegral i * step1, lo2 + fromIntegral j * step2]
                | i <- [0..resolution-1], j <- [0..resolution-1]]
        _ -> [V.replicate dim 0.0]  -- Fallback for higher dimensions

-- | Perform sensitivity analysis
sensitivityAnalysis :: MedicusSpace -> MedicusFunction -> Domain -> String
sensitivityAnalysis _space objective point =
    let dim = V.length point
        epsilon = 1e-4
        baseline = applyFunction (mfFunction objective) point
        sensitivities = [computeSensitivity objective point i epsilon | i <- [0..dim-1]]
    in unlines
        ([ "=== Sensitivity Analysis ==="
        , "Baseline value: " ++ show baseline
        , "Sensitivities by dimension:"
        ] ++ [show i ++ ": " ++ show s | (i, s) <- zip [0..] sensitivities])

-- | Compute sensitivity for one dimension
computeSensitivity :: MedicusFunction -> Domain -> Int -> Double -> Double
computeSensitivity f point dim epsilon =
    let perturbed = V.imap (\i x -> if i == dim then x + epsilon else x) point
        fPlus = applyFunction (mfFunction f) perturbed
        f0 = applyFunction (mfFunction f) point
    in (fPlus - f0) / epsilon

-- | Find feasible region boundaries
findFeasibleRegion :: MedicusSpace -> Int -> String
findFeasibleRegion space numSamples =
    let bounds = domainBounds space
        samples = take numSamples $ generateGridPoints bounds 10
        feasible = filter (checkConstraintSatisfaction space) samples
        feasibleCount = length feasible
        feasibleRate = fromIntegral feasibleCount / fromIntegral numSamples * 100
    in unlines
        [ "=== Feasible Region Analysis ==="
        , "Total samples: " ++ show numSamples
        , "Feasible points: " ++ show feasibleCount
        , "Feasibility rate: " ++ show feasibleRate ++ "%"
        ]

-- ===== Report Generation =====

-- | Complete report data
data ReportData = ReportData
    { rdSpace :: MedicusSpace
    , rdSolution :: Domain
    , rdObjective :: Double
    , rdHistory :: ConvergenceHistory
    }

-- | Generate full analysis report
generateFullReport :: ReportData -> String
generateFullReport rd =
    let space = rdSpace rd
        solution = rdSolution rd
        objective = rdObjective rd
        history = rdHistory rd
    in unlines
        [ "╔══════════════════════════════════════════════════╗"
        , "║         MEDICUS OPTIMIZATION REPORT              ║"
        , "╚══════════════════════════════════════════════════╝"
        , ""
        , "SOLUTION SUMMARY"
        , "----------------"
        , "Objective value: " ++ show objective
        , "Solution dimension: " ++ show (V.length solution)
        , ""
        , plotConvergence history
        , ""
        , visualizeConstraints space solution
        , ""
        , analyzeConvergencePattern history
        , ""
        , "╚══════════════════════════════════════════════════╝"
        ]
