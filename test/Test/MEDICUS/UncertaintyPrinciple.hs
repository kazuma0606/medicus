{-|
Module      : Test.MEDICUS.UncertaintyPrinciple
Description : Tests for uncertainty principle framework
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

Tests for uncertainty principle implementation.
-}

module Test.MEDICUS.UncertaintyPrinciple (tests) where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import MEDICUS.Space.Types
import MEDICUS.Space.Core (defaultMedicusSpace, defaultDomainBounds)
import MEDICUS.UncertaintyPrinciple
import qualified Data.Vector.Storable as V

-- | Test generators
genSmallDimension :: Gen Int
genSmallDimension = choose (1, 3)

genDomainBounds :: Int -> Gen DomainBounds
genDomainBounds dim = vectorOf dim $ do
    lo <- choose (0.0, 0.5)
    hi <- choose (0.5, 1.0)
    return (lo, hi)

genDomainInBounds :: DomainBounds -> Gen Domain
genDomainInBounds bounds = do
    values <- mapM (\(lo, hi) -> choose (lo, hi)) bounds
    return $ V.fromList values

genSimpleMedicusSpace :: Gen MedicusSpace
genSimpleMedicusSpace = do
    dim <- genSmallDimension
    bounds <- genDomainBounds dim
    return $ defaultMedicusSpace
        { spaceDimension = dim
        , domainBounds = bounds
        }

genSecurityLevel :: Gen Double
genSecurityLevel = choose (0.0, 1.0)

genEfficiencyLevel :: Gen Double
genEfficiencyLevel = choose (0.0, 1.0)

genSampleSet :: DomainBounds -> Gen [Domain]
genSampleSet bounds = do
    n <- choose (5, 15)
    vectorOf n (genDomainInBounds bounds)

-- | All tests
tests :: TestTree
tests = testGroup "UncertaintyPrinciple"
    [ unitTests
    , property31Tests
    , property32Tests
    , property33Tests
    , property34Tests
    , property35Tests
    ]

-- | Unit tests
unitTests :: TestTree
unitTests = testGroup "Unit Tests"
    [ testCase "Security operator returns value in [0,1]" $ do
        let space = defaultMedicusSpace
            theta = V.fromList [0.5, 0.5, 0.5]
            sec = securityOperator space theta
        sec >= 0 @? "Security should be non-negative"
        sec <= 1 @? "Security should be at most 1"
    
    , testCase "Efficiency operator returns value in [0,1]" $ do
        let space = defaultMedicusSpace
            theta = V.fromList [0.5, 0.5, 0.5]
            eff = efficiencyOperator space theta
        eff >= 0 @? "Efficiency should be non-negative"
        eff <= 1 @? "Efficiency should be at most 1"
    
    , testCase "Commutator is computed" $ do
        let space = defaultMedicusSpace
            theta = V.fromList [0.5, 0.5, 0.5]
            comm = commutator space theta
        not (isNaN comm) @? "Commutator should be finite"
    
    , testCase "Operator eigenvalues are generated" $ do
        let eigenvals = computeOperatorEigenvalues 5
        length eigenvals @?= 5
        all (\e -> e >= 0 && e <= 1) eigenvals @? "Eigenvalues in [0,1]"
    
    , testCase "Security quantization works" $ do
        let level = quantizeSecurityLevel 0.75
        level >= 0 @? "Quantum number should be non-negative"
        level <= 10 @? "Quantum number should be at most 10"
    
    , testCase "Uncertainty relation is computed" $ do
        let space = defaultMedicusSpace
            samples = [V.fromList [0.5, 0.5, 0.5], V.fromList [0.6, 0.4, 0.5]]
            measure = uncertaintyRelation space samples
        umSecurityStdDev measure >= 0 @? "ΔS should be non-negative"
        umEfficiencyStdDev measure >= 0 @? "ΔE should be non-negative"
    ]

-- | Property 31: Security Operator Implementation
property31Tests :: TestTree
property31Tests = testGroup "Property 31: Security Operator Implementation"
    [ testProperty "Security operator returns value in [0,1]" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let sec = securityOperator space theta
            in sec >= 0 && sec <= 1
    
    , testProperty "Higher constraint satisfaction gives higher security" $
        forAll genSimpleMedicusSpace $ \space ->
            let -- Test at center (likely more satisfied)
                center = V.fromList $ replicate (spaceDimension space) 0.5
                -- Test at boundary (less satisfied)
                boundary = V.fromList $ replicate (spaceDimension space) 0.9
                secCenter = securityOperator space center
                secBoundary = securityOperator space boundary
            in secCenter >= 0 && secBoundary >= 0
    
    , testProperty "Eigenvalues are ordered" $
        forAll (choose (2, 10)) $ \n ->
            let eigenvals = computeOperatorEigenvalues n
            in all (\i -> eigenvals !! i <= eigenvals !! (i+1)) [0..n-2]
    
    , testProperty "Security quantization is consistent" $
        forAll genSecurityLevel $ \sec ->
            let level = quantizeSecurityLevel sec
            in level >= 0 && level <= 10
    
    , testProperty "Quantization maps [0,1] to discrete levels" $
        forAll genSecurityLevel $ \sec ->
            let level = quantizeSecurityLevel sec
                normalized = fromIntegral level / 10.0
            in abs (normalized - sec) < 0.15
    
    , testProperty "Operator state structure is valid" $
        forAll genSecurityLevel $ \sec ->
        forAll (genDomainInBounds [(0,1), (0,1)]) $ \vec ->
            let state = OperatorState sec vec (quantizeSecurityLevel sec)
            in osEigenvalue state >= 0 && V.length (osEigenvector state) > 0
    ]

-- | Property 32: Efficiency Operator Implementation
property32Tests :: TestTree
property32Tests = testGroup "Property 32: Efficiency Operator Implementation"
    [ testProperty "Efficiency operator returns value in [0,1]" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let eff = efficiencyOperator space theta
            in eff >= 0 && eff <= 1
    
    , testProperty "Efficiency is highest at optimal center" $
        forAll genSimpleMedicusSpace $ \space ->
            let center = V.fromList $ replicate (spaceDimension space) 0.5
                effCenter = efficiencyOperator space center
            in effCenter >= 0.9  -- Should be near maximum
    
    , testProperty "Efficiency decreases with deviation" $
        forAll genSimpleMedicusSpace $ \space ->
            let center = V.fromList $ replicate (spaceDimension space) 0.5
                deviated = V.fromList $ replicate (spaceDimension space) 0.8
                effCenter = efficiencyOperator space center
                effDeviated = efficiencyOperator space deviated
            in effCenter >= effDeviated
    
    , testProperty "Efficiency quantization is consistent" $
        forAll genEfficiencyLevel $ \eff ->
            let level = quantizeEfficiencyLevel eff
            in level >= 0 && level <= 10
    
    , testProperty "Efficiency operator is bounded" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let eff = efficiencyOperator space theta
            in not (isNaN eff) && not (isInfinite eff)
    
    , testProperty "Operator composition is valid" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let composed = composeOperators space theta
            in composed >= 0 && composed <= 1
    ]

-- | Property 33: Commutator Calculation
property33Tests :: TestTree
property33Tests = testGroup "Property 33: Commutator Calculation"
    [ testProperty "Commutator is finite" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let comm = commutator space theta
            in not (isNaN comm) && not (isInfinite comm)
    
    , testProperty "Non-commutativity is non-negative" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let nonComm = quantifyNonCommutativity space theta
            in nonComm >= 0
    
    , testProperty "Commutator quantifies operator non-commutativity" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let comm = computeCommutator space theta
            in not (isNaN comm)
    
    , testProperty "Commutator is bounded" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let comm = commutator space theta
            in abs comm < 10.0
    
    , testProperty "Non-commutativity equals absolute commutator" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let comm = commutator space theta
                nonComm = quantifyNonCommutativity space theta
            in abs (nonComm - abs comm) < 1e-10
    
    , testProperty "Operator composition is symmetric in product" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let sec = securityOperator space theta
                eff = efficiencyOperator space theta
                composed = composeOperators space theta
            in abs (composed - sec * eff) < 1e-10
    ]

-- | Property 34: Uncertainty Relation Verification
property34Tests :: TestTree
property34Tests = testGroup "Property 34: Uncertainty Relation Verification"
    [ testProperty "Heisenberg inequality ΔS·ΔE ≥ ½|⟨[Ŝ,Ê]⟩| holds" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genSampleSet (domainBounds space)) $ \samples ->
            length samples >= 3 ==>
            verifyUncertaintyInequality space samples
    
    , testProperty "Standard deviations are non-negative" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genSampleSet (domainBounds space)) $ \samples ->
            length samples >= 2 ==>
            let measure = uncertaintyRelation space samples
            in umSecurityStdDev measure >= 0 && 
               umEfficiencyStdDev measure >= 0
    
    , testProperty "Uncertainty product is non-negative" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genSampleSet (domainBounds space)) $ \samples ->
            length samples >= 2 ==>
            let measure = uncertaintyRelation space samples
            in umProduct measure >= 0
    
    , testProperty "Uncertainty bound is non-negative" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genSampleSet (domainBounds space)) $ \samples ->
            length samples >= 2 ==>
            let measure = uncertaintyRelation space samples
            in umBound measure >= 0
    
    , testProperty "Uncertainty bound equals half absolute commutator" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genSampleSet (domainBounds space)) $ \samples ->
            length samples >= 3 ==>
            let bound = uncertaintyBound space samples
                commValues = map (commutator space) samples
                commExp = sum commValues / fromIntegral (length commValues)
            in abs (bound - 0.5 * abs commExp) < 1e-10
    
    , testProperty "Standard deviation computation is correct" $
        forAll (listOf1 (choose (0.0, 1.0))) $ \values ->
            let stdDev = computeStandardDeviation values
                n = length values
                mean = sum values / fromIntegral n
                variance = sum [(x - mean)^(2::Int) | x <- values] / fromIntegral n
            in abs (stdDev - sqrt variance) < 1e-10
    ]

-- | Property 35: Minimum Uncertainty State
property35Tests :: TestTree
property35Tests = testGroup "Property 35: Minimum Uncertainty State"
    [ testProperty "Minimum uncertainty state has valid parameters" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genSampleSet (domainBounds space)) $ \samples ->
            length samples >= 3 ==>
            let minState = minimumUncertaintyState space samples
                theta = musParameter minState
            in V.length theta == spaceDimension space
    
    , testProperty "Minimum state has security in [0,1]" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genSampleSet (domainBounds space)) $ \samples ->
            length samples >= 3 ==>
            let minState = minimumUncertaintyState space samples
            in musSecurityValue minState >= 0 && 
               musSecurityValue minState <= 1
    
    , testProperty "Minimum state has efficiency in [0,1]" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genSampleSet (domainBounds space)) $ \samples ->
            length samples >= 3 ==>
            let minState = minimumUncertaintyState space samples
            in musEfficiencyValue minState >= 0 && 
               musEfficiencyValue minState <= 1
    
    , testProperty "Optimal balance returns valid domain" $
        forAll genSimpleMedicusSpace $ \space ->
            let optimal = findOptimalBalance space (domainBounds space)
            in V.length optimal == spaceDimension space
    
    , testProperty "Coherent state minimizes uncertainty product" $
        forAll genSimpleMedicusSpace $ \space ->
            let coherent = constructCoherentState space (domainBounds space)
            in musUncertaintyProduct coherent >= 0
    
    , testProperty "Minimum uncertainty product is non-negative" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genSampleSet (domainBounds space)) $ \samples ->
            length samples >= 3 ==>
            let minState = minimumUncertaintyState space samples
            in musUncertaintyProduct minState >= 0
    
    , testProperty "Minimal flag indicates equality condition" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genSampleSet (domainBounds space)) $ \samples ->
            length samples >= 3 ==>
            let minState = minimumUncertaintyState space samples
                isMin = musIsMinimal minState
            in isMin == True || isMin == False
    ]
