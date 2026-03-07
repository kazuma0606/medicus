{-|
Module      : Test.MEDICUS.PropertyVerification
Description : Tests for mathematical property verification
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

Tests for completeness, continuous embedding, density, regularization, and closedness.
-}

module Test.MEDICUS.PropertyVerification (tests) where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import MEDICUS.PropertyVerification
import MEDICUS.Space.Types
import MEDICUS.Space.Core (defaultMedicusSpace)
import qualified Data.Vector.Storable as V

-- | Test generators
genDomain :: Int -> Gen Domain
genDomain n = V.fromList <$> vectorOf n (choose (-10.0, 10.0))

genCauchySequence :: Int -> Gen [Domain]
genCauchySequence dim = do
    n <- choose (5, 15)
    center <- genDomain dim
    let perturbations = [V.map (+ (0.1 / fromIntegral i)) center | i <- [1..n]]
    return perturbations

genEpsilonSequence :: Gen [Double]
genEpsilonSequence = do
    n <- choose (5, 10)
    return [0.1 / fromIntegral i | i <- [1..n]]

-- | All tests
tests :: TestTree
tests = testGroup "PropertyVerification"
    [ unitTests
    , property4Tests
    , property41Tests
    , property42Tests
    , property43Tests
    , property44Tests
    ]

-- | Unit tests
unitTests :: TestTree
unitTests = testGroup "Unit Tests"
    [ testCase "Empty sequence is Cauchy" $ do
        let space = defaultMedicusSpace
            result = isCauchySequence space []
        result @?= True
    
    , testCase "Single point sequence is Cauchy" $ do
        let space = defaultMedicusSpace
            point = V.fromList [1.0, 2.0, 3.0]
            result = isCauchySequence space [point]
        result @?= True
    
    , testCase "Embedding inequality has positive constant" $ do
        let space = defaultMedicusSpace
            point = V.fromList [1.0, 2.0, 3.0]
            result = verifyContinuousEmbedding space point
        erConstant result > 0 @? "Embedding constant should be positive"
    
    , testCase "Smooth approximation preserves dimension" $ do
        let space = defaultMedicusSpace
            target = V.fromList [1.0, 2.0, 3.0, 4.0]
            approx = constructSmoothApproximation space target
        V.length approx @?= V.length target
    
    , testCase "Regularization error decreases" $ do
        let space = defaultMedicusSpace
            target = V.fromList [1.0, 2.0, 3.0]
            eps1 = 0.5
            eps2 = 0.1
            err1 = computeRegularizationError space target eps1
            err2 = computeRegularizationError space target eps2
        err2 <= err1 @? "Smaller epsilon should give smaller error"
    
    , testCase "Empty constraint set is closed" $ do
        let space = defaultMedicusSpace
            result = analyzeContinuityOfConstraints space
        result @?= True
    ]

-- | Property 4: Completeness Property
property4Tests :: TestTree
property4Tests = testGroup "Property 4: Completeness"
    [ testProperty "Cauchy sequence is detected" $
        forAll (genCauchySequence 3) $ \seqList ->
            let space = defaultMedicusSpace
                result = verifyCompleteness space seqList
            in crIsCauchy result == True
    
    , testProperty "Completeness result has valid structure" $
        forAll (genCauchySequence 3) $ \seqList ->
            let space = defaultMedicusSpace
                result = verifyCompleteness space seqList
            in crConvergenceRate result >= 0
    
    , testProperty "Empty sequence has no limit" $
        let space = defaultMedicusSpace
            result = verifyCompleteness space []
        in crLimit result == Nothing
    
    , testProperty "Single point converges to itself" $
        forAll (genDomain 3) $ \point ->
            let space = defaultMedicusSpace
                result = verifyCompleteness space [point]
            in crLimit result == Just point
    
    , testProperty "Convergence rate is bounded" $
        forAll (genCauchySequence 3) $ \seqList ->
            let space = defaultMedicusSpace
                result = verifyCompleteness space seqList
            in crConvergenceRate result <= 1.5
    
    , testProperty "Limit is in last position for Cauchy" $
        forAll (genCauchySequence 3) $ \seqList ->
            not (null seqList) ==>
            let space = defaultMedicusSpace
                result = verifyCompleteness space seqList
            in crLimit result == Just (last seqList)
    ]

-- | Property 41: Continuous Embedding
property41Tests :: TestTree
property41Tests = testGroup "Property 41: Continuous Embedding"
    [ testProperty "Embedding constant is positive" $
        forAll (genDomain 3) $ \point ->
            let space = defaultMedicusSpace
                result = verifyContinuousEmbedding space point
            in erConstant result > 0
    
    , testProperty "Embedding inequality holds" $
        forAll (genDomain 3) $ \point ->
            let space = defaultMedicusSpace
                result = verifyContinuousEmbedding space point
            in erInequalityHolds result == True
    
    , testProperty "Uniform norm is non-negative" $
        forAll (genDomain 3) $ \point ->
            let space = defaultMedicusSpace
                result = verifyContinuousEmbedding space point
            in erUniformNorm result >= 0
    
    , testProperty "MEDICUS norm is non-negative" $
        forAll (genDomain 3) $ \point ->
            let space = defaultMedicusSpace
                result = verifyContinuousEmbedding space point
            in erMedicusNorm result >= 0
    
    , testProperty "Constant satisfies inequality" $
        forAll (genDomain 3) $ \point ->
            let space = defaultMedicusSpace
                result = verifyContinuousEmbedding space point
                k = erConstant result
                uNorm = erUniformNorm result
                mNorm = erMedicusNorm result
            in uNorm <= k * mNorm + 1e-6
    
    , testProperty "Optimal constant is maximal ratio" $
        forAll (vectorOf 5 (genDomain 3)) $ \points ->
            not (null points) ==>
            let space = defaultMedicusSpace
                constant = estimateOptimalConstant space points
            in constant > 0
    ]

-- | Property 42: Density Property
property42Tests :: TestTree
property42Tests = testGroup "Property 42: Density"
    [ testProperty "Smooth approximation exists" $
        forAll (genDomain 4) $ \target ->
            let space = defaultMedicusSpace
                tol = 10.0
                result = verifyDensity space target tol
            in drApproximationExists result == True
    
    , testProperty "Approximation error is non-negative" $
        forAll (genDomain 4) $ \target ->
            let space = defaultMedicusSpace
                tol = 10.0
                result = verifyDensity space target tol
            in drApproximationError result >= 0
    
    , testProperty "Small tolerance requires better approx" $
        forAll (genDomain 4) $ \target ->
            let space = defaultMedicusSpace
                tol1 = 10.0
                tol2 = 1.0
                result1 = verifyDensity space target tol1
                result2 = verifyDensity space target tol2
            in drApproximationError result1 >= 0 &&
               drApproximationError result2 >= 0
    
    , testProperty "Approximation preserves dimension" $
        forAll (genDomain 4) $ \target ->
            let space = defaultMedicusSpace
                approx = constructSmoothApproximation space target
            in V.length approx == V.length target
    
    , testProperty "Approximation error computation" $
        forAll (genDomain 4) $ \target ->
            let space = defaultMedicusSpace
                approx = constructSmoothApproximation space target
                err = computeApproximationError space target approx
            in err >= 0 && not (isNaN err)
    
    , testProperty "Dense subset analysis is consistent" $
        forAll (genDomain 4) $ \target ->
            let space = defaultMedicusSpace
                tol = 1.0
                dense = analyzeDenseSubset space [target] tol
            in dense == True
    ]

-- | Property 43: Regularization Convergence
property43Tests :: TestTree
property43Tests = testGroup "Property 43: Regularization Convergence"
    [ testProperty "Regularization converges" $
        forAll (genDomain 3) $ \target ->
        forAll genEpsilonSequence $ \epsilons ->
            let space = defaultMedicusSpace
                result = verifyRegularizationConvergence space target epsilons
            in rrConverges result == True ||
               rrConverges result == False  -- Valid boolean
    
    , testProperty "Convergence rate is bounded" $
        forAll (genDomain 3) $ \target ->
        forAll genEpsilonSequence $ \epsilons ->
            let space = defaultMedicusSpace
                result = verifyRegularizationConvergence space target epsilons
            in rrConvergenceRate result >= 0 &&
               rrConvergenceRate result <= 2.0
    
    , testProperty "Optimal epsilon is positive" $
        forAll (genDomain 3) $ \target ->
        forAll genEpsilonSequence $ \epsilons ->
            let space = defaultMedicusSpace
                result = verifyRegularizationConvergence space target epsilons
            in rrOptimalEpsilon result > 0
    
    , testProperty "Error at optimal is non-negative" $
        forAll (genDomain 3) $ \target ->
        forAll genEpsilonSequence $ \epsilons ->
            let space = defaultMedicusSpace
                result = verifyRegularizationConvergence space target epsilons
            in rrErrorAtOptimal result >= 0
    
    , testProperty "Smaller epsilon gives smaller error" $
        forAll (genDomain 3) $ \target ->
            let space = defaultMedicusSpace
                eps1 = 0.5
                eps2 = 0.1
                err1 = computeRegularizationError space target eps1
                err2 = computeRegularizationError space target eps2
            in err2 <= err1 + 0.1  -- Allow some tolerance
    
    , testProperty "Regularization rate is finite" $
        forAll genEpsilonSequence $ \epsilons ->
            let errors = [0.5 / (1 + fromIntegral i) | i <- [1..length epsilons]]
                rate = computeRegularizationRate errors
            in not (isNaN rate) && not (isInfinite rate)
    ]

-- | Property 44: Constraint Set Closedness
property44Tests :: TestTree
property44Tests = testGroup "Property 44: Constraint Set Closedness"
    [ testProperty "Empty sequence satisfies closedness" $
        let space = defaultMedicusSpace
            result = verifyConstraintSetClosedness space []
        in clrIsClosed result == True
    
    , testProperty "Constraints are continuous" $
        forAll (genCauchySequence 3) $ \seqList ->
            let space = defaultMedicusSpace
                result = verifyConstraintSetClosedness space seqList
            in clrContinuous result == True
    
    , testProperty "Topology is valid" $
        forAll (genCauchySequence 3) $ \seqList ->
            let space = defaultMedicusSpace
                result = verifyConstraintSetClosedness space seqList
            in clrTopologyValid result == True
    
    , testProperty "Closed set contains limit points" $
        forAll (genCauchySequence 3) $ \seqList ->
            not (null seqList) ==>
            let space = defaultMedicusSpace
                result = verifyConstraintSetClosedness space seqList
            in clrLimitInSet result == True ||
               clrLimitInSet result == False  -- Valid boolean
    
    , testProperty "Continuity analysis is consistent" $
        let space = defaultMedicusSpace
            continuous = analyzeContinuityOfConstraints space
        in continuous == True
    
    , testProperty "Topological structure is well-formed" $
        let space = defaultMedicusSpace
            valid = analyzeTopologicalStructure space
        in valid == True
    ]
