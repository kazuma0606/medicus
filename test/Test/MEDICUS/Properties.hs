{-|
Module      : Test.MEDICUS.Properties
Description : Property-based tests for mathematical guarantees
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Property-based testing using QuickCheck to verify mathematical properties
of MEDICUS space theory.
-}

module Test.MEDICUS.Properties (tests) where

import Test.Tasty
import Test.Tasty.QuickCheck
import qualified Data.Vector.Storable as V

import MEDICUS.Space.Core
import MEDICUS.Space.Types
import MEDICUS.PropertyVerification
import Test.MEDICUS.Generators

tests :: TestTree
tests = testGroup "Mathematical Properties"
    [ property1Tests
    , property2Tests
    , property3Tests
    , basicPropertyTests
    ]

-- | Property 1: MEDICUS Space Construction
-- For any parameter domain Ω and constraint set C, 
-- the system should construct a valid MEDICUS function space M(Ω,C)
property1Tests :: TestTree
property1Tests = testGroup "Property 1: MEDICUS Space Construction"
    [ testProperty "Space dimension is preserved" $
        forAll genSmallDimension $ \dim ->
        forAll (genDomainBounds dim) $ \bounds ->
        forAll genNormWeights $ \weights ->
        forAll genTolerance $ \tol ->
            let space = createMedicusSpace dim bounds [] weights tol
            in spaceDimension space === dim
    
    , testProperty "Domain bounds are preserved" $
        forAll genSmallDimension $ \dim ->
        forAll (genDomainBounds dim) $ \bounds ->
            let space = createMedicusSpace dim bounds [] defaultNormWeights 1e-6
            in domainBounds space === bounds
    
    , testProperty "Norm weights are preserved" $
        forAll genNormWeights $ \weights ->
            let space = createMedicusSpace 3 defaultDomainBounds [] weights 1e-6
            in normWeights space === weights
    
    , testProperty "Tolerance is preserved" $
        forAll genTolerance $ \tol ->
            let space = createMedicusSpace 3 defaultDomainBounds [] defaultNormWeights tol
            in tolerance space === tol
    
    , testProperty "Constraints are preserved" $
        -- For now, test with empty constraints
        let space = createMedicusSpace 3 defaultDomainBounds [] defaultNormWeights 1e-6
        in null (constraints space)
    
    , testProperty "Default space has correct dimensions" $
        spaceDimension defaultMedicusSpace === 3
    
    , testProperty "Default space has unit cube bounds" $
        domainBounds defaultMedicusSpace === [(0, 1), (0, 1), (0, 1)]
    ]

-- | Property 2: Space Membership Verification
property2Tests :: TestTree
property2Tests = testGroup "Property 2: Space Membership Verification"
    [ testProperty "Constant function belongs to space" $
        forAll arbitrary $ \c ->
            let mf = constantFunction c
            in belongsToSpace defaultMedicusSpace mf
    
    , testProperty "Linear function belongs to space" $
        forAll (genLinearFunction 3) $ \mf ->
            belongsToSpace defaultMedicusSpace mf
    
    , testProperty "Quadratic function belongs to space" $
        forAll (genQuadraticFunction 3) $ \mf ->
            belongsToSpace defaultMedicusSpace mf
    ]

-- | Property 3: Linear Space Operations
property3Tests :: TestTree
property3Tests = testGroup "Property 3: Linear Space Operations"
    [ testProperty "Function addition is commutative" $
        forAll genConstantFunction $ \f1 ->
        forAll genConstantFunction $ \f2 ->
            let theta = domainZero 3
                sum1 = applyFunction (mfFunction (addFunctions f1 f2)) theta
                sum2 = applyFunction (mfFunction (addFunctions f2 f1)) theta
            in abs (sum1 - sum2) < 1e-10
    
    , testProperty "Scalar multiplication distributes" $
        forAll arbitrary $ \alpha ->
        forAll genConstantFunction $ \f ->
            let theta = domainZero 3
                scaled = applyFunction (mfFunction (scalarMultiply alpha f)) theta
                original = applyFunction (mfFunction f) theta
            in abs (scaled - alpha * original) < 1e-10
    
    , testProperty "Zero scalar gives zero function" $
        forAll genConstantFunction $ \f ->
            let theta = domainZero 3
                result = applyFunction (mfFunction (scalarMultiply 0 f)) theta
            in abs result < 1e-10
    
    , testProperty "Unit scalar preserves function" $
        forAll genConstantFunction $ \f ->
            let theta = domainZero 3
                scaled = applyFunction (mfFunction (scalarMultiply 1 f)) theta
                original = applyFunction (mfFunction f) theta
            in abs (scaled - original) < 1e-10
    
    , testProperty "Sum of functions remains in space" $
        forAll genConstantFunction $ \f1 ->
        forAll genConstantFunction $ \f2 ->
            let sum_f = addFunctions f1 f2
            in belongsToSpace defaultMedicusSpace sum_f
    
    , testProperty "Scalar multiple remains in space" $
        forAll arbitrary $ \alpha ->
        forAll genConstantFunction $ \f ->
            let scaled = scalarMultiply alpha f
            in belongsToSpace defaultMedicusSpace scaled
    ]

-- | Basic mathematical properties
basicPropertyTests :: TestTree
basicPropertyTests = testGroup "Basic Mathematical Properties"
    [ testProperty "Completeness verification" $
        verifyCompleteness defaultMedicusSpace === True
    
    , testProperty "Continuous embedding verification" $
        verifyContinuousEmbedding defaultMedicusSpace === True
    
    , testProperty "Density verification" $
        verifyDensity defaultMedicusSpace === True
    
    , testProperty "Domain zero has correct dimension" $
        forAll genSmallDimension $ \dim ->
            V.length (domainZero dim) === dim
    
    , testProperty "Domain from list preserves length" $
        forAll (listOf (arbitrary :: Gen Double)) $ \xs ->
            not (null xs) ==>
            V.length (domainFromList xs) === length xs
    
    , testProperty "Point in bounds is correctly detected" $
        forAll genSmallDimension $ \dim ->
        forAll (genDomainBounds dim) $ \bounds ->
        forAll (genDomainInBounds bounds) $ \point ->
            inDomainBounds bounds point === True
    
    , testProperty "Norm is non-negative" $
        forAll genConstantFunction $ \f ->
            norm f >= 0
    
    , testProperty "Distance is symmetric" $
        forAll genConstantFunction $ \f1 ->
        forAll genConstantFunction $ \f2 ->
            abs (distance f1 f2 - distance f2 f1) < 1e-10
    
    , testProperty "Distance to self is zero" $
        forAll genConstantFunction $ \f ->
            distance f f === 0
    ]
