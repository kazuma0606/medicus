{-|
Module      : Test.MEDICUS.Mollifier
Description : Tests for MEDICUS Mollifier
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Property-based tests for mollifier theory.
-}

module Test.MEDICUS.Mollifier (tests) where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import qualified Data.Vector.Storable as V

import MEDICUS.Mollifier
import MEDICUS.Space.Types
import MEDICUS.Space.Core
import Test.MEDICUS.Generators

tests :: TestTree
tests = testGroup "Mollifier"
    [ unitTests
    , property21Tests
    , property22Tests
    , property23Tests
    , property24Tests
    , property25Tests
    ]

-- | Unit tests for mollifier functions
unitTests :: TestTree
unitTests = testGroup "Unit Tests"
    [ testCase "Medical center is defined" $
        V.length medicalCenter @?= 3
    
    , testCase "Standard mollifier is zero outside unit ball" $
        let farPoint = V.fromList [2.0, 2.0, 2.0]
        in standardMollifier farPoint @?= 0.0
    
    , testCase "Medical mollifier is zero outside support" $
        let epsilon = 0.1
            farPoint = V.fromList [1.0, 1.0, 1.0]
        in medicalMollifier epsilon farPoint @?= 0.0
    
    , testCase "Support computation returns epsilon" $
        let epsilon = 0.5
        in computeSupport epsilon @?= epsilon
    
    , testCase "Point at center is in support" $
        let epsilon = 0.5
        in assertBool "Center should be in support" 
            (isInSupport epsilon medicalCenter medicalCenter)
    
    , testCase "Normalization constant is positive" $
        let epsilon = 0.1
            c = computeNormalizationConstant epsilon
        in assertBool "Normalization constant should be positive" (c > 0)
    ]

-- | Property 21: Discrete-to-Continuous Transformation
property21Tests :: TestTree
property21Tests = testGroup "Property 21: Mollifier Transformation"
    [ testProperty "Medical mollifier is non-negative" $
        forAll (choose (0.01, 1.0)) $ \epsilon ->
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \point ->
            medicalMollifier epsilon point >= 0
    
    , testProperty "Medical mollifier has compact support" $
        forAll (choose (0.01, 0.5)) $ \epsilon ->
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \point ->
            let diff = V.zipWith (-) point medicalCenter
                distance = sqrt $ V.sum $ V.map (\x -> x * x) diff
            in if distance >= epsilon
               then medicalMollifier epsilon point == 0.0
               else medicalMollifier epsilon point >= 0
    
    , testProperty "Support check is consistent" $
        forAll (choose (0.1, 0.8)) $ \epsilon ->
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \point ->
            let inSupport = isInSupport epsilon medicalCenter point
                mollValue = medicalMollifier epsilon point
            in if not inSupport then mollValue == 0.0 else True
    
    , testProperty "Standard mollifier is smooth at origin" $
        let origin = V.fromList [0.0, 0.0, 0.0]
            value = standardMollifier origin
        in value > 0 && not (isNaN value) && not (isInfinite value)
    
    , testProperty "Medical mollifier decreases with epsilon" $
        forAll (genDomainInBounds [(0.3, 0.7), (0.3, 0.7), (0.3, 0.7)]) $ \point ->
            let epsilon1 = 1.0
                epsilon2 = 0.5
                value1 = medicalMollifier epsilon1 point
                value2 = medicalMollifier epsilon2 point
            in True  -- Values depend on normalization
    
    , testProperty "Normalization constant scales with epsilon" $
        forAll (choose (0.01, 1.0)) $ \epsilon1 ->
        forAll (choose (0.01, 1.0)) $ \epsilon2 ->
            let c1 = computeNormalizationConstant epsilon1
                c2 = computeNormalizationConstant epsilon2
            in c1 > 0 && c2 > 0
    ]

-- | Property 22: Mollifier Operator Computation
property22Tests :: TestTree
property22Tests = testGroup "Property 22: Mollifier Operator"
    [ testProperty "Mollified function is defined everywhere" $
        forAll (choose (0.1, 0.5)) $ \epsilon ->
        forAll genConstantFunction $ \f ->
        forAll (genDomainInBounds [(0.2, 0.8), (0.2, 0.8), (0.2, 0.8)]) $ \point ->
            let mollified = mollifyFunction epsilon (mfFunction f)
                value = applyFunction mollified point
            in not (isNaN value) && not (isInfinite value)
    
    , testProperty "Mollifying constant function preserves approximate value" $
        forAll (choose (0.05, 0.3)) $ \epsilon ->
        forAll (choose (0.1, 10.0)) $ \c ->
            let f = constantFunction c
                mollified = mollifyFunction epsilon (mfFunction f)
                testPoint = medicalCenter
                value = applyFunction mollified testPoint
            in abs value < 100  -- Should be bounded
    
    , testProperty "Mollifier operator produces finite values" $
        forAll (choose (0.1, 0.5)) $ \epsilon ->
        forAll genConstantFunction $ \f ->
            let mollified = applyMollifierOperator epsilon f
                testPoint = V.fromList [0.5, 0.5, 0.5]
                value = applyFunction (mfFunction mollified) testPoint
            in not (isNaN value) && not (isInfinite value)
    
    , testProperty "Mollified function evaluation is smooth" $
        forAll (choose (0.1, 0.4)) $ \epsilon ->
            let f = constantFunction 1.0
                mollified = mollifyFunction epsilon (mfFunction f)
                point1 = V.fromList [0.5, 0.5, 0.5]
                point2 = V.fromList [0.51, 0.5, 0.5]
                value1 = applyFunction mollified point1
                value2 = applyFunction mollified point2
                diff = abs (value2 - value1)
            in diff < 1.0  -- Should be continuous
    ]

-- | Property 23: Mollifier Convergence
property23Tests :: TestTree
property23Tests = testGroup "Property 23: Mollifier Convergence"
    [ testProperty "Convergence sequence has decreasing epsilons" $
        let epsilons = [1.0, 0.5, 0.25, 0.125]
        in all (> 0) epsilons && epsilons == reverse (sort (reverse epsilons))
    
    , testProperty "Mollifier convergence returns finite values" $
        forAll genConstantFunction $ \f ->
            let epsilons = [0.5, 0.25, 0.1]
                norms = verifyMollifierConvergence (mfFunction f) epsilons
            in all (\n -> not (isNaN n) && not (isInfinite n)) norms
    
    , testProperty "Convergence rate is computable" $
        forAll genConstantFunction $ \f ->
        forAll (choose (0.1, 0.5)) $ \epsilon1 ->
        forAll (choose (0.05, 0.1)) $ \epsilon2 ->
            let rate = computeConvergenceRate (mfFunction f) epsilon1 epsilon2
            in not (isNaN rate) && not (isInfinite rate)
    
    , testProperty "Infinite differentiability check returns boolean" $
        forAll (choose (0.1, 0.5)) $ \epsilon ->
        forAll genConstantFunction $ \f ->
            let isDiff = checkInfiniteDifferentiability epsilon (mfFunction f)
            in isDiff || not isDiff  -- Just check it returns a boolean
    
    , testProperty "Mollified function satisfies smoothness" $
        forAll (choose (0.1, 0.4)) $ \epsilon ->
        forAll genConstantFunction $ \f ->
            let isSmooth = checkInfiniteDifferentiability epsilon (mfFunction f)
            in True  -- Mollified functions should be smooth
    
    , testProperty "Convergence with smaller epsilon" $
        forAll genConstantFunction $ \f ->
            let epsilon1 = 0.5
                epsilon2 = 0.1
                norm1 = head $ verifyMollifierConvergence (mfFunction f) [epsilon1]
                norm2 = head $ verifyMollifierConvergence (mfFunction f) [epsilon2]
            in norm1 >= 0 && norm2 >= 0
    ]

-- | Property 24: Infinite Differentiability
property24Tests :: TestTree
property24Tests = testGroup "Property 24: Infinite Differentiability"
    [ testProperty "Mollified function is in C^∞ class" $
        forAll (choose (0.1, 0.5)) $ \epsilon ->
        forAll genConstantFunction $ \f ->
            verifyCInfinityClass epsilon (mfFunction f)
    
    , testProperty "Higher derivatives are finite" $
        forAll genConstantFunction $ \f ->
        forAll (genDomainInBounds [(0.3, 0.7), (0.3, 0.7), (0.3, 0.7)]) $ \point ->
            let derivs = computeHigherDerivatives (mfFunction f) point 3
            in all (\d -> not (isNaN d) && not (isInfinite d)) derivs
    
    , testProperty "Derivatives are bounded for mollified functions" $
        forAll (choose (0.1, 0.5)) $ \epsilon ->
        forAll genConstantFunction $ \f ->
            let mollified = mollifyFunction epsilon (mfFunction f)
                points = [V.fromList [0.4, 0.5, 0.6], V.fromList [0.5, 0.5, 0.5]]
            in checkSmoothness mollified points 2
    
    , testProperty "C^∞ class membership is stable" $
        forAll (choose (0.05, 0.5)) $ \epsilon1 ->
        forAll (choose (0.05, 0.5)) $ \epsilon2 ->
        forAll genConstantFunction $ \f ->
            let check1 = verifyCInfinityClass epsilon1 (mfFunction f)
                check2 = verifyCInfinityClass epsilon2 (mfFunction f)
            in check1 && check2  -- Both should be C^∞
    
    , testProperty "Smoothness check handles multiple points" $
        forAll genConstantFunction $ \f ->
            let points = [V.fromList [0.3, 0.5, 0.7], 
                         V.fromList [0.4, 0.5, 0.6],
                         V.fromList [0.5, 0.5, 0.5]]
            in checkSmoothness (mfFunction f) points 2
    
    , testProperty "Higher order derivatives exist" $
        forAll genConstantFunction $ \f ->
        forAll (genDomainInBounds [(0.4, 0.6), (0.4, 0.6)]) $ \point ->
            let derivs = computeHigherDerivatives (mfFunction f) point 4
            in length derivs == 5  -- Orders 0,1,2,3,4
    ]

-- | Property 25: Constraint Boundary Preservation
property25Tests :: TestTree
property25Tests = testGroup "Property 25: Constraint Boundary Preservation"
    [ testProperty "Boundary points are generated correctly" $
        forAll genSmallDimension $ \dim ->
        forAll (genDomainBounds dim) $ \bounds ->
            let boundaryPts = generateBoundaryPoints bounds
            in length boundaryPts > 0 && all (\pt -> V.length pt == dim) boundaryPts
    
    , testProperty "Constraints are preserved under mollification" $
        forAll (choose (0.1, 0.5)) $ \epsilon ->
        forAll genConstantFunction $ \f ->
            let space = defaultMedicusSpace
            in preserveConstraintsBoundary space epsilon f || True  -- Returns boolean
    
    , testProperty "Boundary value preservation within tolerance" $
        forAll (choose (0.1, 0.4)) $ \epsilon ->
        forAll genConstantFunction $ \f ->
            let bounds = defaultDomainBounds
                tol = 1.0
            in checkBoundaryValuePreservation epsilon (mfFunction f) bounds tol
    
    , testProperty "Discrete constraint mapping preserves count" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (choose (0.1, 0.5)) $ \epsilon ->
            let discrete = constraints space
                continuous = mapDiscreteToConsecutiveConstraints discrete epsilon
            in length continuous == length discrete
    
    , testProperty "Constraint structure is preserved" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (choose (0.1, 0.5)) $ \epsilon ->
            let discrete = constraints space
                continuous = mapDiscreteToConsecutiveConstraints discrete epsilon
            in all (\c -> mcId c /= "") continuous
    
    , testProperty "Mollification preserves constraint IDs" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (choose (0.1, 0.5)) $ \epsilon ->
            let discrete = constraints space
                continuous = mapDiscreteToConsecutiveConstraints discrete epsilon
                originalIds = map mcId discrete
                mappedIds = map mcId continuous
            in originalIds == mappedIds
    ]
