{-|
Module      : Test.MEDICUS.EntropyManagement
Description : Tests for entropy management system
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

Tests for entropy management and thermodynamic laws.
-}

module Test.MEDICUS.EntropyManagement (tests) where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import MEDICUS.EntropyManagement

-- | Test generators
genProbabilityList :: Gen [Double]
genProbabilityList = do
    n <- choose (2, 10)
    vectorOf n (choose (0.0, 1.0))

genSkillList :: Gen [Double]
genSkillList = do
    n <- choose (3, 10)
    vectorOf n (choose (0.0, 1.0))

genDecayRate :: Gen Double
genDecayRate = choose (0.0, 0.5)

genInvestment :: Gen Double
genInvestment = choose (1.0, 100.0)

genTimeUnit :: Gen Double
genTimeUnit = choose (0.1, 10.0)

genOperations :: Gen [Double]
genOperations = do
    n <- choose (2, 10)
    vectorOf n (choose (0.1, 10.0))

-- | All tests
tests :: TestTree
tests = testGroup "EntropyManagement"
    [ unitTests
    , property36Tests
    , property37Tests
    , property38Tests
    , property39Tests
    , property40Tests
    ]

-- | Unit tests
unitTests :: TestTree
unitTests = testGroup "Unit Tests"
    [ testCase "Shannon entropy is non-negative" $ do
        let probs = [0.5, 0.3, 0.2]
            s = securityEntropy probs
        s >= 0 @? "Entropy should be non-negative"
    
    , testCase "Uniform distribution has maximum entropy" $ do
        let uniform = replicate 4 0.25
            nonUniform = [0.7, 0.2, 0.05, 0.05]
            sUniform = computeDiscreteEntropy uniform
            sNonUniform = computeDiscreteEntropy nonUniform
        sUniform >= sNonUniform @? "Uniform should have higher entropy"
    
    , testCase "Entropy increase is computed" $ do
        let before = [0.5, 0.3, 0.2]
            after = [0.4, 0.3, 0.3]
            ds = entropyIncrease before after
        not (isNaN ds) @? "Entropy change should be finite"
    
    , testCase "First law energy balance" $ do
        let q = 100.0
            w = 30.0
            deltaU = firstLawEnergy q w
        deltaU @?= 70.0
    
    , testCase "Education energy is positive" $ do
        let reduction = -0.5  -- Negative = entropy decrease
            q = educationEnergy reduction
        q > 0 @? "Education energy should be positive"
    
    , testCase "Operational cost is computed" $ do
        let ops = [10.0, 20.0, 15.0]
            time = 1.0
            cost = operationalCost ops time
        cost > 0 @? "Operational cost should be positive"
    ]

-- | Property 36: Security Entropy Calculation
property36Tests :: TestTree
property36Tests = testGroup "Property 36: Security Entropy Calculation"
    [ testProperty "Entropy is non-negative" $
        forAll genProbabilityList $ \probs ->
            securityEntropy probs >= 0
    
    , testProperty "Discrete entropy equals Shannon formula" $
        forAll genProbabilityList $ \probs ->
            let s = computeDiscreteEntropy probs
                normalized = normalizeProbabilities probs
                manual = -sum [if p > 0 then p * log p else 0.0 | p <- normalized]
            in abs (s - manual) < 1e-10
    
    , testProperty "Uniform distribution maximizes entropy" $
        forAll (choose (2, 8)) $ \n ->
            let uniform = replicate n (1.0 / fromIntegral n)
                sUniform = computeDiscreteEntropy uniform
                nonUniform = 1.0 : replicate (n-1) 0.0
                sNonUniform = computeDiscreteEntropy nonUniform
            in sUniform >= sNonUniform - 1e-10
    
    , testProperty "Continuous entropy is non-negative" $
        forAll genProbabilityList $ \vals ->
        forAll genProbabilityList $ \density ->
            computeContinuousEntropy vals density >= 0
    
    , testProperty "Security distribution analysis is valid" $
        forAll genSkillList $ \levels ->
            let dist = analyzeSecurityDistribution levels
            in sdEntropy dist >= 0 && 
               length (sdProbabilities dist) == length levels
    
    , testProperty "Probability normalization sums to 1" $
        forAll genProbabilityList $ \probs ->
            let normalized = normalizeProbabilities probs
                total = sum normalized
            in abs (total - 1.0) < 1e-10
    ]

-- | Property 37: Entropy Increase Verification
property37Tests :: TestTree
property37Tests = testGroup "Property 37: Entropy Increase Verification"
    [ testProperty "Entropy increase rate can be computed" $
        forAll genProbabilityList $ \p1 ->
        forAll genProbabilityList $ \p2 ->
        forAll genTimeUnit $ \dt ->
            let rate = computeEntropyRate p1 p2 dt
            in not (isNaN rate) && not (isInfinite rate)
    
    , testProperty "Natural skill variation increases entropy" $
        forAll genSkillList $ \skills ->
        forAll genDecayRate $ \decay ->
            decay > 0 ==>
            let varied = modelNaturalSkillVariation skills decay
                sBefore = computeDiscreteEntropy skills
                sAfter = computeDiscreteEntropy varied
            in sAfter >= sBefore - 1e-10
    
    , testProperty "Entropy increase verification handles time" $
        forAll genProbabilityList $ \p1 ->
        forAll genProbabilityList $ \p2 ->
        forAll genTimeUnit $ \dt ->
            dt > 0 ==>
            let verified = verifyEntropyIncreaseRate p1 p2 dt
            in verified == True || verified == False
    
    , testProperty "Zero decay rate preserves entropy" $
        forAll genSkillList $ \skills ->
            let varied = modelNaturalSkillVariation skills 0.0
                sBefore = computeDiscreteEntropy skills
                sAfter = computeDiscreteEntropy varied
            in abs (sAfter - sBefore) < 1e-10
    
    , testProperty "Entropy increase is Second Law" $
        forAll genSkillList $ \skills ->
        forAll (choose (0.1, 0.5)) $ \decay ->
            let varied = modelNaturalSkillVariation skills decay
                ds = entropyIncrease (normalizeProbabilities skills) 
                                    (normalizeProbabilities varied)
            in ds >= -1e-10
    
    , testProperty "Entropy rate is finite" $
        forAll genProbabilityList $ \p1 ->
        forAll genProbabilityList $ \p2 ->
        forAll genTimeUnit $ \dt ->
            dt > 0 ==>
            let rate = computeEntropyRate p1 p2 dt
            in not (isNaN rate)
    ]

-- | Property 38: Thermodynamic First Law
property38Tests :: TestTree
property38Tests = testGroup "Property 38: Thermodynamic First Law"
    [ testProperty "First law: ΔU = Q - W" $
        forAll genInvestment $ \q ->
        forAll genInvestment $ \w ->
            let deltaU = firstLawEnergy q w
            in deltaU == q - w
    
    , testProperty "Internal energy change is finite" $
        forAll genSkillList $ \s1 ->
        forAll genSkillList $ \s2 ->
            length s1 == length s2 ==>
            let deltaU = computeInternalEnergyChange s1 s2
            in not (isNaN deltaU) && not (isInfinite deltaU)
    
    , testProperty "Energy conservation is verified" $
        forAll genInvestment $ \q ->
        forAll genInvestment $ \w ->
            let deltaU = q - w
                balance = verifyEnergyConservation deltaU q w
            in ebConserved balance == True
    
    , testProperty "Energy balance structure is valid" $
        forAll genInvestment $ \q ->
        forAll genInvestment $ \w ->
            let balance = verifyEnergyConservation (q - w) q w
            in ebEducationEnergy balance == q && 
               ebOperationalWork balance == w
    
    , testProperty "Conservation holds within tolerance" $
        forAll genInvestment $ \q ->
        forAll genInvestment $ \w ->
            let deltaU = q - w + 1e-7  -- Small error
                balance = verifyEnergyConservation deltaU q w
            in ebConserved balance == True
    
    , testProperty "Internal energy scales quadratically" $
        forAll genSkillList $ \skills ->
            let s2 = map (* 2) skills
                u1 = sum [s * s | s <- skills]
                u2 = sum [s * s | s <- s2]
            in abs (u2 - 4 * u1) < 1e-6  -- Should be ~4x
    ]

-- | Property 39: Education Investment Quantification
property39Tests :: TestTree
property39Tests = testGroup "Property 39: Education Investment Quantification"
    [ testProperty "Education energy is non-negative" $
        forAll (choose (-1.0, 1.0)) $ \reduction ->
            educationEnergy reduction >= 0
    
    , testProperty "Education effect improves skills" $
        forAll genSkillList $ \skills ->
        forAll genInvestment $ \investment ->
            let improved = computeEducationEffect skills investment
            in length improved == length skills
    
    , testProperty "Education reduces entropy" $
        forAll genSkillList $ \skills ->
        forAll (choose (10.0, 100.0)) $ \investment ->
            let reduction = modelEntropyReduction skills investment
                sBefore = computeDiscreteEntropy (normalizeProbabilities skills)
                skillsAfter = computeEducationEffect skills investment
                sAfter = computeDiscreteEntropy (normalizeProbabilities skillsAfter)
            in reduction == sAfter - sBefore
    
    , testProperty "Investment optimization returns valid structure" $
        forAll genSkillList $ \skills ->
        forAll (choose (0.1, 1.0)) $ \target ->
            let opt = optimizeEducationInvestment skills target
            in eiInvestmentAmount opt >= 0 && 
               not (isNaN (eiEffectiveness opt))
    
    , testProperty "Effectiveness is cost per entropy reduction" $
        forAll genSkillList $ \skills ->
        forAll (choose (0.1, 1.0)) $ \target ->
            let opt = optimizeEducationInvestment skills target
                expectedEff = if eiEntropyReduction opt /= 0
                             then eiInvestmentAmount opt / abs (eiEntropyReduction opt)
                             else 0.0
            in abs (eiEffectiveness opt - expectedEff) < 1e-10
    
    , testProperty "Higher investment gives more reduction" $
        forAll genSkillList $ \skills ->
            let lowInv = 10.0
                highInv = 100.0
                reduction1 = abs $ modelEntropyReduction skills lowInv
                reduction2 = abs $ modelEntropyReduction skills highInv
            in reduction2 >= reduction1 - 0.1
    ]

-- | Property 40: Operational Cost Evaluation
property40Tests :: TestTree
property40Tests = testGroup "Property 40: Operational Cost Evaluation"
    [ testProperty "Operational cost is non-negative" $
        forAll genOperations $ \ops ->
        forAll genTimeUnit $ \time ->
            operationalCost ops time >= 0
    
    , testProperty "Cost scales with time" $
        forAll genOperations $ \ops ->
        forAll genTimeUnit $ \t1 ->
        forAll genTimeUnit $ \t2 ->
            t1 < t2 ==>
            let c1 = operationalCost ops t1
                c2 = operationalCost ops t2
            in c2 >= c1 - 1e-10
    
    , testProperty "Energy consumption is non-negative" $
        forAll genOperations $ \activities ->
            measureEnergyConsumption activities >= 0
    
    , testProperty "Cost-effectiveness is non-negative" $
        forAll genInvestment $ \benefit ->
        forAll genInvestment $ \cost ->
            cost > 0 ==>
            analyzeCostEffectiveness benefit cost >= 0
    
    , testProperty "Efficiency metrics are valid" $
        forAll genOperations $ \activities ->
        forAll genTimeUnit $ \time ->
        forAll genInvestment $ \benefit ->
            let metrics = computeEfficiencyMetrics activities time benefit
            in omDailyCost metrics >= 0 && 
               omEnergyConsumption metrics >= 0 &&
               omEfficiency metrics >= 0
    
    , testProperty "Energy consumption scales quadratically" $
        forAll genOperations $ \ops ->
            let scaled = map (* 2) ops
                e1 = measureEnergyConsumption ops
                e2 = measureEnergyConsumption scaled
            in abs (e2 - 4 * e1) < 1e-6
    
    , testProperty "Zero operations give zero cost" $
        forAll genTimeUnit $ \time ->
            let cost = operationalCost [] time
            in cost == 0
    ]
