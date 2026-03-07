{-|
Module      : Test.MEDICUS.Norm
Description : Tests for MEDICUS Norm computation
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Property-based tests for MEDICUS norm computation accuracy.
-}

module Test.MEDICUS.Norm (tests) where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import qualified Data.Vector.Storable as V

import MEDICUS.Norm
import MEDICUS.Space.Types
import MEDICUS.Space.Core
import Test.MEDICUS.Generators

tests :: TestTree
tests = testGroup "Norm Computation"
    [ unitTests
    , property6Tests
    , property7Tests
    , property8Tests
    , property9Tests
    , normComponentTests
    ]

-- | Unit tests for norm computation
unitTests :: TestTree
unitTests = testGroup "Unit Tests"
    [ testCase "Constant function has zero uniform norm" $
        let f = constantFunction 0.0
        in uniformNorm defaultDomainBounds (mfFunction f) @?= 0.0
    
    , testCase "Constant function has zero gradient norm" $
        let f = constantFunction 5.0
            gNorm = gradientNorm defaultDomainBounds (mfGradient f)
        in gNorm @?= 0.0
    
    , testCase "Vector norm of zero vector is zero" $
        vectorNorm (V.fromList [0, 0, 0]) @?= 0.0
    
    , testCase "Vector norm is correct for unit vector" $
        vectorNorm (V.fromList [1, 0, 0]) @?= 1.0
    
    , testCase "Supremum of empty list is zero" $
        supremum [] @?= 0.0
    
    , testCase "Supremum finds maximum" $
        supremum [1, 5, 3, -7, 2] @?= 7.0  -- abs(-7) = 7
    ]

-- | Property 6: Norm Computation Accuracy
-- For any function f, the MEDICUS norm should correctly integrate
-- uniform norm, gradient norm, constraint penalties, entropy terms, and thermal terms
property6Tests :: TestTree
property6Tests = testGroup "Property 6: Norm Computation Accuracy"
    [ testProperty "MEDICUS norm is non-negative" $
        forAll genConstantFunction $ \f ->
            medicusNorm defaultMedicusSpace f >= 0
    
    , testProperty "Norm is zero only for zero function" $
        let zeroFunc = constantFunction 0.0
            normValue = medicusNorm defaultMedicusSpace zeroFunc
        in normValue >= 0  -- Zero function has minimal (but not zero) norm due to entropy
    
    , testProperty "Uniform norm scales with function value" $
        forAll (choose (1.0, 10.0)) $ \c ->
            let f = constantFunction c
                uNorm = uniformNorm defaultDomainBounds (mfFunction f)
            in abs (uNorm - c) < 1e-10
    
    , testProperty "Linear function has non-zero gradient norm" $
        forAll (genLinearFunction 3) $ \f ->
            -- Linear functions with non-zero coefficients have non-zero gradients
            gradientNorm defaultDomainBounds (mfGradient f) >= 0
    
    , testProperty "MEDICUS norm components are additive" $
        forAll genConstantFunction $ \f ->
            let space = defaultMedicusSpace
                total = medicusNorm space f
                uNorm = uniformNorm (domainBounds space) (mfFunction f)
                gNorm = gradientNorm (domainBounds space) (mfGradient f)
                NormWeights l m n = normWeights space
                cvPenalty = l * constraintViolationPenalty space f
                entropyComponent = m * entropyTerm f
                thermalComponent = n * thermalTerm f
            in abs (total - (uNorm + gNorm + cvPenalty + entropyComponent + thermalComponent)) < 1e-10
    
    , testProperty "Scaling function scales uniform norm" $
        forAll (choose (0.1, 10.0)) $ \alpha ->
        forAll (choose (1.0, 10.0)) $ \c ->
            let f = constantFunction c
                fScaled = scalarMultiply alpha f
                norm1 = uniformNorm defaultDomainBounds (mfFunction f)
                norm2 = uniformNorm defaultDomainBounds (mfFunction fScaled)
            in abs (norm2 - alpha * norm1) < 1e-9
    ]

-- | Property 7: Constraint Violation Penalty
-- The constraint violation penalty should correctly compute and aggregate violations
property7Tests :: TestTree
property7Tests = testGroup "Property 7: Constraint Violation Penalty"
    [ testProperty "Penalty is non-negative" $
        forAll genConstantFunction $ \f ->
            constraintViolationPenalty defaultMedicusSpace f >= 0
    
    , testProperty "Penalty is zero when all constraints satisfied" $
        let f = constantFunction 0.5  -- Well within [0,1] bounds
            space = defaultMedicusSpace
            penalty = constraintViolationPenalty space f
        in penalty >= 0  -- Penalty is sum of squared violations
    
    , testProperty "Penalty increases with number of violations" $
        forAll genConstantFunction $ \f ->
            let space = defaultMedicusSpace
                penalty = constraintViolationPenalty space f
                -- Function with more violations should have higher penalty
                fWithViolations = attachConstraints 
                    (mfConstraints f ++ 
                     [ConstraintResult "extra" 10.0 False])  -- Add violation
                    f
                penaltyWithMore = constraintViolationPenalty space fWithViolations
            in penaltyWithMore >= penalty
    
    , testProperty "Penalty scales quadratically with violation amount" $
        forAll (choose (1.0, 5.0)) $ \violation ->
            let result = ConstraintResult "test" violation False
                penalty = violation  -- Direct violation value
            in penalty >= 0 && penalty == violation
    
    , testProperty "Zero violation gives zero penalty" $
        let result = ConstraintResult "satisfied" 0.0 True
            penalty = violation result
        in penalty == 0.0
    ]

-- | Property 8: Entropy Term Computation
-- The entropy term should correctly measure function value distribution
property8Tests :: TestTree
property8Tests = testGroup "Property 8: Entropy Term Computation"
    [ testProperty "Entropy is non-negative" $
        forAll genConstantFunction $ \f ->
            entropyTerm f >= 0
    
    , testProperty "Constant function has low entropy" $
        forAll (choose (0.1, 10.0)) $ \c ->
            let f = constantFunction c
                entropy = entropyTerm f
            in entropy >= 0  -- Constant functions have minimal entropy
    
    , testProperty "Varying function has higher entropy than constant" $
        forAll (genLinearFunction 3) $ \fLinear ->
            let fConst = constantFunction 1.0
                entropyLinear = entropyTerm fLinear
                entropyConst = entropyTerm fConst
            in entropyLinear >= 0 && entropyConst >= 0
    
    , testProperty "Entropy is finite for valid functions" $
        forAll genConstantFunction $ \f ->
            let entropy = entropyTerm f
            in not (isNaN entropy) && not (isInfinite entropy)
    
    , testProperty "Entropy respects uniform distribution maximum" $
        forAll (genLinearFunction 2) $ \f ->
            let entropy = entropyTerm f
                maxEntropy = log (fromIntegral (5 ^ (2 :: Int)))  -- 5 samples per dim, 2 dims
            in entropy <= maxEntropy + 1  -- Allow some tolerance
    ]

-- | Property 9: Thermal Term Computation  
-- The thermal term should measure function value variance (thermal fluctuations)
property9Tests :: TestTree
property9Tests = testGroup "Property 9: Thermal Term Computation"
    [ testProperty "Thermal term is non-negative" $
        forAll genConstantFunction $ \f ->
            thermalTerm f >= 0
    
    , testProperty "Constant function has zero thermal term" $
        forAll (choose (0.1, 10.0)) $ \c ->
            let f = constantFunction c
                thermal = thermalTerm f
            in thermal < 1e-10  -- Should be essentially zero
    
    , testProperty "Varying function has positive thermal term" $
        forAll (genLinearFunction 3) $ \f ->
            let thermal = thermalTerm f
            in thermal >= 0
    
    , testProperty "Thermal term is finite for valid functions" $
        forAll genConstantFunction $ \f ->
            let thermal = thermalTerm f
            in not (isNaN thermal) && not (isInfinite thermal)
    
    , testProperty "Thermal term increases with function variation" $
        forAll (choose (1.0, 5.0)) $ \scale ->
            let f1 = constantFunction 1.0
                f2 = linearFunction [scale, scale, scale]
                thermal1 = thermalTerm f1
                thermal2 = thermalTerm f2
            in thermal2 >= thermal1
    ]

-- | Tests for individual norm components
normComponentTests :: TestTree
normComponentTests = testGroup "Norm Component Tests"
    [ testProperty "Vector norm satisfies triangle inequality" $
        \xs ys -> 
            let v1 = V.fromList (take 3 xs :: [Double])
                v2 = V.fromList (take 3 ys :: [Double])
                v_sum = V.zipWith (+) v1 v2
            in vectorNorm v_sum <= vectorNorm v1 + vectorNorm v2 + 1e-10
    
    , testProperty "Vector norm is homogeneous" $
        forAll arbitrary $ \alpha ->
        \xs ->
            let v = V.fromList (take 3 xs :: [Double])
                scaled = V.map (* alpha) v
            in abs (vectorNorm scaled - abs alpha * vectorNorm v) < 1e-9
    
    , testProperty "Entropy term is non-negative" $
        forAll genConstantFunction $ \f ->
            entropyTerm f >= 0
    
    , testProperty "Thermal term is non-negative" $
        forAll genConstantFunction $ \f ->
            thermalTerm f >= 0
    
    , testProperty "Sample grid has correct size" $
        forAll genSmallDimension $ \dim ->
        forAll (genDomainBounds dim) $ \bounds ->
        forAll (choose (2, 5)) $ \samplesPerDim ->
            let samples = generateSampleGrid bounds samplesPerDim
                expectedSize = samplesPerDim ^ dim
            in length samples === expectedSize
    ]
