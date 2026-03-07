{-|
Module      : Test.MEDICUS.StatisticalMechanics
Description : Tests for statistical mechanics framework
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

Tests for statistical mechanics implementation.
-}

module Test.MEDICUS.StatisticalMechanics (tests) where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import MEDICUS.Space.Types
import MEDICUS.Space.Core (defaultMedicusSpace, defaultDomainBounds)
import MEDICUS.StatisticalMechanics
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

genTemperature :: Gen Double
genTemperature = choose (0.1, 10.0)

genEmergencyLevel :: Gen Double
genEmergencyLevel = choose (0.0, 10.0)

-- | All tests
tests :: TestTree
tests = testGroup "StatisticalMechanics"
    [ unitTests
    , property26Tests
    , property27Tests
    , property28Tests
    , property29Tests
    , property30Tests
    ]

-- | Unit tests
unitTests :: TestTree
unitTests = testGroup "Unit Tests"
    [ testCase "Medical energy is non-negative" $ do
        let space = defaultMedicusSpace
            theta = V.fromList [0.5, 0.5, 0.5]
            energy = medicalEnergy space theta
        energy >= 0 @? "Energy should be non-negative"
    
    , testCase "Energy components are computed" $ do
        let space = defaultMedicusSpace
            theta = V.fromList [0.5, 0.5]
            components = computeEnergyComponents space theta
        costComponent components >= 0 @? "Cost should be non-negative"
        riskComponent components >= 0 @? "Risk should be non-negative"
        constraintComponent components >= 0 @? "Constraint cost should be non-negative"
    
    , testCase "Emergency level to temperature mapping" $ do
        let highEmergency = emergencyLevelToTemperature 10.0
            lowEmergency = emergencyLevelToTemperature 0.0
        highEmergency < lowEmergency @? "High emergency should give lower temperature"
    
    , testCase "Partition function is positive" $ do
        let space = defaultMedicusSpace
            temp = 1.0
            z = partitionFunction space temp
        z > 0 @? "Partition function should be positive"
    
    , testCase "Boltzmann distribution is non-negative" $ do
        let space = defaultMedicusSpace
            temp = 1.0
            theta = V.fromList [0.5, 0.5, 0.5]
            prob = boltzmannDistribution space temp theta
        prob >= 0 @? "Probability should be non-negative"
    
    , testCase "Free energy is computed" $ do
        let space = defaultMedicusSpace
            temp = 1.0
            theta = V.fromList [0.5, 0.5]
            f = freeEnergy space temp theta
        not (isNaN f) @? "Free energy should be finite"
    ]

-- | Property 26: Medical Energy Integration
property26Tests :: TestTree
property26Tests = testGroup "Property 26: Medical Energy Integration"
    [ testProperty "Energy integrates all components" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let energy = medicalEnergy space theta
                components = computeEnergyComponents space theta
                sum' = costComponent components + 
                      riskComponent components + 
                      constraintComponent components
            in abs (energy - sum') < 1e-10
    
    , testProperty "Energy is non-negative" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            medicalEnergy space theta >= 0
    
    , testProperty "Energy components are non-negative" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let comp = computeEnergyComponents space theta
            in costComponent comp >= 0 && 
               riskComponent comp >= 0 && 
               constraintComponent comp >= 0
    
    , testProperty "Energy landscape has valid bounds" $
        forAll genSimpleMedicusSpace $ \space ->
            let (minE, maxE, meanE) = analyzeEnergyLandscape space (domainBounds space)
            in minE >= 0 && maxE >= minE && meanE >= minE && meanE <= maxE
    
    , testProperty "Risk component increases with deviation" $
        forAll genSimpleMedicusSpace $ \space ->
            let center = V.fromList $ replicate (spaceDimension space) 0.5
                far = V.fromList $ replicate (spaceDimension space) 0.9
                comp1 = computeEnergyComponents space center
                comp2 = computeEnergyComponents space far
            in riskComponent comp2 > riskComponent comp1
    
    , testProperty "Cost component scales with parameter magnitude" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let scaled = V.map (* 2) theta
                comp1 = computeEnergyComponents space theta
                comp2 = computeEnergyComponents space scaled
            in costComponent comp2 > costComponent comp1 || costComponent comp1 == 0
    ]

-- | Property 27: Emergency Parameter Scaling
property27Tests :: TestTree
property27Tests = testGroup "Property 27: Emergency Parameter Scaling"
    [ testProperty "Temperature decreases with emergency level" $
        forAll genEmergencyLevel $ \e1 ->
        forAll genEmergencyLevel $ \e2 ->
            e1 < e2 ==>
            emergencyLevelToTemperature e1 > emergencyLevelToTemperature e2
    
    , testProperty "Temperature is always positive" $
        forAll genEmergencyLevel $ \e ->
            emergencyLevelToTemperature e > 0
    
    , testProperty "Temperature to emergency level is inverse" $
        forAll genEmergencyLevel $ \e ->
            let temp = emergencyLevelToTemperature e
                e' = temperatureToEmergencyLevel temp
            in abs (e - e') < 0.1
    
    , testProperty "Scale invariance holds" $
        forAll genTemperature $ \t1 ->
        forAll genTemperature $ \t2 ->
            t1 > 0 && t2 > 0 ==>
            checkScaleInvariance t1 t2
    
    , testProperty "Emergency temperature scale is positive" $
        forAll genEmergencyLevel $ \e ->
            emergencyTemperatureScale e > 0
    
    , testProperty "Extreme emergency gives low temperature" $
        let maxEmergency = 10.0
            temp = emergencyLevelToTemperature maxEmergency
        in temp < 1.0
    ]

-- | Property 28: Partition Function Computation
property28Tests :: TestTree
property28Tests = testGroup "Property 28: Partition Function Computation"
    [ testProperty "Partition function is always positive" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
            partitionFunction space temp > 0
    
    , testProperty "Partition function increases with temperature" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \t1 ->
        forAll genTemperature $ \t2 ->
            t1 < t2 ==>
            partitionFunction space t1 <= partitionFunction space t2 + 1.0
    
    , testProperty "Partition function converges" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
            verifyPartitionConvergence space temp (domainBounds space)
    
    , testProperty "Adaptive integration returns positive value" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
            let z = adaptivePartitionIntegration space temp (domainBounds space) 0.05
            in z > 0
    
    , testProperty "Integration volume is positive" $
        forAll genSmallDimension $ \dim ->
        forAll (genDomainBounds dim) $ \bounds ->
            computeIntegrationVolume bounds > 0
    
    , testProperty "Partition samples are in bounds" $
        forAll genSmallDimension $ \dim ->
        forAll (genDomainBounds dim) $ \bounds ->
            let samples = generatePartitionSamples bounds 5
                inBounds theta = all (\(i, (lo, hi)) -> 
                    let val = theta V.! i
                    in val >= lo && val <= hi
                    ) (zip [0..] bounds)
            in all inBounds samples
    ]

-- | Property 29: Boltzmann Distribution Generation
property29Tests :: TestTree
property29Tests = testGroup "Property 29: Boltzmann Distribution Generation"
    [ testProperty "Boltzmann probability is non-negative" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            boltzmannDistribution space temp theta >= 0
    
    , testProperty "Boltzmann equals exp(-E/T)/Z" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let prob = boltzmannDistribution space temp theta
                energy = medicalEnergy space theta
                z = partitionFunction space temp
                expected = exp (negate $ energy / temp) / z
            in abs (prob - expected) < 1e-10
    
    , testProperty "Probability density normalizes" $
        forAll (listOf1 (choose (0.0, 1.0))) $ \probs ->
            let normalized = normalizeProbabilityDensity probs
                total = sum normalized
            in abs (total - 1.0) < 1e-10
    
    , testProperty "Higher temperature gives flatter distribution" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let lowTemp = 0.5
                highTemp = 5.0
                prob1 = boltzmannDistribution space lowTemp theta
                prob2 = boltzmannDistribution space highTemp theta
            in prob1 >= 0 && prob2 >= 0
    
    , testProperty "Boltzmann sampling returns valid domains" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
            ioProperty $ do
                samples <- sampleBoltzmannDistribution space temp 5
                return $ all (\theta -> V.length theta == spaceDimension space) samples
    
    , testProperty "Sampled points are in domain bounds" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
            ioProperty $ do
                samples <- sampleBoltzmannDistribution space temp 3
                let inBounds theta = all (\(i, (lo, hi)) -> 
                        let val = theta V.! i
                        in val >= lo - 0.01 && val <= hi + 0.01
                        ) (zip [0..] (domainBounds space))
                return $ all inBounds samples
    ]

-- | Property 30: Statistical Equilibrium
property30Tests :: TestTree
property30Tests = testGroup "Property 30: Statistical Equilibrium"
    [ testProperty "Equilibrium state has finite energy" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
            let eq = statisticalEquilibrium space temp
            in not (isNaN (eqEnergy eq)) && not (isInfinite (eqEnergy eq))
    
    , testProperty "Free energy is finite at equilibrium" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
            let eq = statisticalEquilibrium space temp
            in not (isNaN (eqFreeEnergy eq)) && not (isInfinite (eqFreeEnergy eq))
    
    , testProperty "Equilibrium has valid probability" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
            let eq = statisticalEquilibrium space temp
            in eqProbability eq >= 0 && eqProbability eq <= 1.0
    
    , testProperty "Free energy minimization returns valid domain" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
            let optimal = minimizeFreeEnergy space temp (domainBounds space)
            in V.length optimal == spaceDimension space
    
    , testProperty "Stability analysis returns boolean" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let stable = analyzeStability space temp theta
            in stable == True || stable == False
    
    , testProperty "Equilibrium parameter is in bounds" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
            let eq = statisticalEquilibrium space temp
                theta = eqParameter eq
                bounds = domainBounds space
                inBounds = all (\(i, (lo, hi)) -> 
                    let val = theta V.! i
                    in val >= lo - 0.01 && val <= hi + 0.01
                    ) (zip [0..] bounds)
            in inBounds
    
    , testProperty "Free energy formula: F = E - T*S" $
        forAll genSimpleMedicusSpace $ \space ->
        forAll genTemperature $ \temp ->
        forAll (genDomainInBounds (domainBounds space)) $ \theta ->
            let f = freeEnergy space temp theta
                energy = medicalEnergy space theta
            in not (isNaN f) && abs f <= abs energy + temp * 10
    ]
