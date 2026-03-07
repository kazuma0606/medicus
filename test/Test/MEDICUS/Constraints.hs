{-|
Module      : Test.MEDICUS.Constraints
Description : Tests for Medical Constraints
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Property-based tests for medical constraint system.
-}

module Test.MEDICUS.Constraints (tests) where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import qualified Data.Vector.Storable as V

import MEDICUS.Constraints
import MEDICUS.Space.Types
import Test.MEDICUS.Generators

tests :: TestTree
tests = testGroup "Medical Constraints"
    [ unitTests
    , property11Tests
    , property12Tests
    , property13Tests
    , property14Tests
    , property15Tests
    ]

-- | Unit tests for constraint creation
unitTests :: TestTree
unitTests = testGroup "Unit Tests"
    [ testCase "Privacy constraint creation" $
        mcId (createPrivacyConstraint 0.8) @?= "PRIVACY_C1"
    
    , testCase "Emergency constraint priority" $
        mcPriority (createEmergencyConstraint 100.0) @?= Critical
    
    , testCase "Availability constraint ID" $
        mcId (createAvailabilityConstraint 0.99) @?= "AVAILABILITY_C3"
    
    , testCase "Compliance constraint target" $
        case mcType createComplianceConstraint of
            Equality target -> target @?= 1.0
            _ -> assertFailure "Compliance constraint should be Equality type"
    
    , testCase "Privacy level in valid range" $
        let theta = V.fromList [0.8, 0.7, 0.9]
            level = privacyLevel theta
        in assertBool "Privacy level should be in [0,1]" (level >= 0 && level <= 1)
    
    , testCase "Emergency response time is positive" $
        let theta = V.fromList [0.5, 0.5]
            time = emergencyResponseTime theta
        in assertBool "Response time should be positive" (time > 0)
    ]

-- | Property 11: Privacy Constraint Implementation
property11Tests :: TestTree
property11Tests = testGroup "Property 11: Privacy Constraint"
    [ testProperty "Privacy level is in [0,1] range" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let level = privacyLevel theta
            in level >= 0 && level <= 1
    
    , testProperty "Privacy constraint violation is non-negative" $
        forAll (choose (0.0, 1.0)) $ \minLevel ->
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let mc = createPrivacyConstraint minLevel
                violation = constraintViolationAmount mc theta
            in violation >= 0
    
    , testProperty "High privacy parameters give high privacy level" $
        let highPrivacy = V.fromList [1.0, 1.0, 1.0]
            lowPrivacy = V.fromList [0.0, 0.0, 0.0]
        in privacyLevel highPrivacy >= privacyLevel lowPrivacy
    
    , testProperty "Privacy constraint satisfied when level exceeds minimum" $
        forAll (choose (0.0, 0.5)) $ \minLevel ->
        let highPrivacy = V.fromList [1.0, 1.0, 1.0]
            mc = createPrivacyConstraint minLevel
        in satisfiesConstraint mc highPrivacy
    
    , testProperty "Privacy constraint violated when level below minimum" $
        forAll (choose (0.9, 1.0)) $ \minLevel ->
        let lowPrivacy = V.fromList [0.0, 0.0, 0.0]
            mc = createPrivacyConstraint minLevel
        in not (satisfiesConstraint mc lowPrivacy)
    
    , testProperty "Privacy level is weighted average" $
        forAll (choose (0.0, 1.0)) $ \enc ->
        forAll (choose (0.0, 1.0)) $ \acc ->
        forAll (choose (0.0, 1.0)) $ \aud ->
            let theta = V.fromList [enc, acc, aud]
                level = privacyLevel theta
                expected = 0.5 * enc + 0.3 * acc + 0.2 * aud
            in abs (level - expected) < 1e-10
    ]

-- | Property 12: Emergency Response Constraint
property12Tests :: TestTree
property12Tests = testGroup "Property 12: Emergency Response Constraint"
    [ testProperty "Response time is positive" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            emergencyResponseTime theta > 0
    
    , testProperty "Emergency constraint violation is non-negative" $
        forAll (choose (50.0, 200.0)) $ \maxTime ->
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let mc = createEmergencyConstraint maxTime
                violation = constraintViolationAmount mc theta
            in violation >= 0
    
    , testProperty "High system load increases response time" $
        let lowLoad = V.fromList [0.1, 0.9]
            highLoad = V.fromList [0.9, 0.9]
        in emergencyResponseTime highLoad >= emergencyResponseTime lowLoad
    
    , testProperty "High resource allocation decreases response time" $
        let lowResource = V.fromList [0.5, 0.1]
            highResource = V.fromList [0.5, 0.9]
        in emergencyResponseTime lowResource >= emergencyResponseTime highResource
    
    , testProperty "Emergency constraint satisfied when time is under limit" $
        let fastSystem = V.fromList [0.1, 0.9]
            mc = createEmergencyConstraint 200.0
        in satisfiesConstraint mc fastSystem
    
    , testProperty "Response time scales with system parameters" $
        forAll (choose (0.0, 1.0)) $ \load ->
        forAll (choose (0.0, 1.0)) $ \resource ->
            let theta = V.fromList [load, resource]
                time = emergencyResponseTime theta
                baseTime = 50.0
                expected = baseTime * (1.0 + load) * (2.0 - resource)
            in abs (time - expected) < 1e-10
    ]

-- | Property 13: Availability Constraint
property13Tests :: TestTree
property13Tests = testGroup "Property 13: System Availability Constraint"
    [ testProperty "Availability is in [0,1] range" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let avail = systemAvailability theta
            in avail >= 0 && avail <= 1
    
    , testProperty "Availability constraint violation is non-negative" $
        forAll (choose (0.90, 0.99)) $ \minAvail ->
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let mc = createAvailabilityConstraint minAvail
                violation = constraintViolationAmount mc theta
            in violation >= 0
    
    , testProperty "High redundancy increases availability" $
        let lowRedundancy = V.fromList [0.1, 0.5, 0.5]
            highRedundancy = V.fromList [0.9, 0.5, 0.5]
        in systemAvailability highRedundancy >= systemAvailability lowRedundancy
    
    , testProperty "High failover increases availability" $
        let lowFailover = V.fromList [0.5, 0.1, 0.5]
            highFailover = V.fromList [0.5, 0.9, 0.5]
        in systemAvailability highFailover >= systemAvailability lowFailover
    
    , testProperty "High maintenance load decreases availability" $
        let lowMaintenance = V.fromList [0.5, 0.5, 0.9]
            highMaintenance = V.fromList [0.5, 0.5, 0.1]
        in systemAvailability lowMaintenance >= systemAvailability highMaintenance
    
    , testProperty "Availability constraint satisfied for robust systems" $
        let robustSystem = V.fromList [1.0, 1.0, 1.0]
            mc = createAvailabilityConstraint 0.95
        in satisfiesConstraint mc robustSystem
    ]

-- | Property 14: Compliance Constraint
property14Tests :: TestTree
property14Tests = testGroup "Property 14: Regulatory Compliance Constraint"
    [ testProperty "Compliance score is binary (0 or 1)" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let score = complianceScore theta
            in score == 0.0 || score == 1.0
    
    , testProperty "Full compliance requires all parameters >= 0.99" $
        let fullCompliance = V.fromList [1.0, 1.0, 1.0]
        in complianceScore fullCompliance == 1.0
    
    , testProperty "Partial compliance gives score 0" $
        let partialCompliance = V.fromList [1.0, 0.95, 1.0]
        in complianceScore partialCompliance == 0.0
    
    , testProperty "No compliance gives score 0" $
        let noCompliance = V.fromList [0.0, 0.0, 0.0]
        in complianceScore noCompliance == 0.0
    
    , testProperty "Compliance constraint violation is zero for full compliance" $
        let fullCompliance = V.fromList [1.0, 1.0, 1.0]
            mc = createComplianceConstraint
        in satisfiesConstraint mc fullCompliance
    
    , testProperty "Compliance constraint violated for partial compliance" $
        let partialCompliance = V.fromList [0.95, 0.95, 0.95]
            mc = createComplianceConstraint
        in not (satisfiesConstraint mc partialCompliance)
    ]

-- | Property 15: Constraint Combination Satisfiability
property15Tests :: TestTree
property15Tests = testGroup "Property 15: Constraint Combination"
    [ testProperty "Empty constraint set is always satisfiable" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            checkConstraintSatisfiability [] theta
    
    , testProperty "Single satisfied constraint is satisfiable" $
        let goodSystem = V.fromList [1.0, 1.0, 1.0]
            constraints' = [createPrivacyConstraint 0.5]
        in checkConstraintSatisfiability constraints' goodSystem
    
    , testProperty "Combined violation is sum of individual violations" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let constraints' = [createPrivacyConstraint 0.8, createAvailabilityConstraint 0.95]
                combined = combinedConstraintViolation constraints' theta
                individual = sum [constraintViolationAmount c theta | c <- constraints']
            in abs (combined - individual) < 1e-10
    
    , testProperty "All constraints satisfied implies satisfiability" $
        let excellentSystem = V.fromList [1.0, 1.0, 1.0]
            constraints' = [ createPrivacyConstraint 0.5
                          , createAvailabilityConstraint 0.95
                          , createComplianceConstraint
                          ]
        in checkConstraintSatisfiability constraints' excellentSystem
    
    , testProperty "Simultaneous satisfaction check returns correct satisfaction status" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let constraints' = [createPrivacyConstraint 0.5]
                (allSat, _) = checkSimultaneousSatisfaction constraints' theta
                checkSat = checkConstraintSatisfiability constraints' theta
            in allSat == checkSat
    
    , testProperty "Simultaneous satisfaction violations list matches failed constraints" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let constraints' = [createPrivacyConstraint 0.5, createAvailabilityConstraint 0.95]
                (_, violations) = checkSimultaneousSatisfaction constraints' theta
                expected = [mcId c | c <- constraints', not (satisfiesConstraint c theta)]
            in violations == expected
    
    , testProperty "No conflicts detected when all constraints satisfied" $
        let perfectSystem = V.fromList [1.0, 1.0, 1.0]
            constraints' = [ createPrivacyConstraint 0.5
                          , createEmergencyConstraint 200.0
                          , createAvailabilityConstraint 0.95
                          ]
            conflicts = detectConstraintConflicts constraints' perfectSystem
        in null conflicts
    
    , testProperty "Combined violation is non-negative" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let constraints' = [createPrivacyConstraint 0.8, createAvailabilityConstraint 0.99]
                combined = combinedConstraintViolation constraints' theta
            in combined >= 0
    
    , testProperty "Adding constraints increases or maintains violation" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let c1 = [createPrivacyConstraint 0.8]
                c2 = c1 ++ [createAvailabilityConstraint 0.99]
                v1 = combinedConstraintViolation c1 theta
                v2 = combinedConstraintViolation c2 theta
            in v2 >= v1
    
    , testProperty "Multiple identical constraints multiply violation" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \theta ->
            let c = createPrivacyConstraint 0.8
                single = combinedConstraintViolation [c] theta
                double = combinedConstraintViolation [c, c] theta
            in abs (double - 2 * single) < 1e-10
    ]
