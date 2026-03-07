{-|
Module      : MEDICUS.Constraints
Description : Medical constraint system
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

This module implements medical-specific constraints:
- Privacy protection (HIPAA, GDPR)
- Emergency response time
- System availability
- Regulatory compliance
-}

module MEDICUS.Constraints
    ( -- * Constraint Types
      createPrivacyConstraint
    , createEmergencyConstraint
    , createAvailabilityConstraint
    , createComplianceConstraint
    
      -- * Constraint Evaluation
    , evaluateConstraint
    , checkAllConstraints
    , satisfiesConstraint
    , constraintViolationAmount
    
      -- * Constraint Combination
    , checkConstraintSatisfiability
    , detectConstraintConflicts
    , checkSimultaneousSatisfaction
    , combinedConstraintViolation
    
      -- * Constraint Functions
    , privacyLevel
    , emergencyResponseTime
    , systemAvailability
    , complianceScore
    ) where

import MEDICUS.Space.Types
import qualified Data.Vector.Storable as V

-- | Privacy level function: measures data protection level
-- Based on encryption strength, access controls, and audit logging
privacyLevel :: Domain -> Double
privacyLevel theta =
    let n = V.length theta
        -- Weighted average of privacy-related parameters
        encryptionStrength = if n > 0 then theta V.! 0 else 0.5
        accessControl = if n > 1 then theta V.! 1 else 0.5
        auditLogging = if n > 2 then theta V.! 2 else 0.5
        weights = V.fromList [0.5, 0.3, 0.2]
        values = V.fromList [encryptionStrength, accessControl, auditLogging]
    in V.sum (V.zipWith (*) weights values)

-- | Create privacy protection constraint
createPrivacyConstraint :: Double -> MedicalConstraint
createPrivacyConstraint minLevel = MedicalConstraint
    { mcId = "PRIVACY_C1"
    , mcType = Inequality minLevel
    , mcPriority = Critical
    , mcDescription = "Privacy level must meet minimum threshold: " ++ show minLevel
    , mcEvaluator = privacyLevel
    }

-- | Emergency response time function: measures system response time in milliseconds
-- Lower is better; based on system load and resource allocation
emergencyResponseTime :: Domain -> Double
emergencyResponseTime theta =
    let n = V.length theta
        -- Response time increases with complexity, decreases with resources
        systemLoad = if n > 0 then theta V.! 0 else 0.5
        resourceAllocation = if n > 1 then theta V.! 1 else 0.5
        -- Base response time 50ms, scaled by load and resources
        baseTime = 50.0
        loadFactor = 1.0 + systemLoad
        resourceFactor = 2.0 - resourceAllocation
    in baseTime * loadFactor * resourceFactor

-- | Create emergency response constraint
createEmergencyConstraint :: Double -> MedicalConstraint
createEmergencyConstraint maxTime = MedicalConstraint
    { mcId = "EMERGENCY_C2"
    , mcType = Inequality maxTime
    , mcPriority = Critical
    , mcDescription = "Emergency response time must be under " ++ show maxTime ++ "ms"
    , mcEvaluator = \theta -> maxTime - emergencyResponseTime theta
    }

-- | System availability function: measures uptime percentage
-- Based on redundancy, failover capability, and maintenance
systemAvailability :: Domain -> Double
systemAvailability theta =
    let n = V.length theta
        redundancy = if n > 0 then theta V.! 0 else 0.5
        failoverCapability = if n > 1 then theta V.! 1 else 0.5
        maintenance = if n > 2 then theta V.! 2 else 0.5
        -- Availability calculation: weighted geometric mean
        -- High redundancy and failover increase availability
        base = 0.95  -- Base 95% availability
        redundancyBoost = redundancy * 0.04
        failoverBoost = failoverCapability * 0.009
        maintenancePenalty = (1.0 - maintenance) * 0.01
    in min 1.0 (base + redundancyBoost + failoverBoost - maintenancePenalty)

-- | Create system availability constraint
createAvailabilityConstraint :: Double -> MedicalConstraint
createAvailabilityConstraint minAvail = MedicalConstraint
    { mcId = "AVAILABILITY_C3"
    , mcType = Inequality minAvail
    , mcPriority = Important
    , mcDescription = "System availability must be at least " ++ show (minAvail * 100) ++ "%"
    , mcEvaluator = systemAvailability
    }

-- | Regulatory compliance score: 1.0 for full compliance
-- Based on HIPAA, GDPR, and other regulations
complianceScore :: Domain -> Double
complianceScore theta =
    let n = V.length theta
        hipaaCompliance = if n > 0 then theta V.! 0 else 0.0
        gdprCompliance = if n > 1 then theta V.! 1 else 0.0
        otherCompliance = if n > 2 then theta V.! 2 else 0.0
        -- All must be 1.0 for full compliance
        allCompliant = all (>= 0.99) [hipaaCompliance, gdprCompliance, otherCompliance]
    in if allCompliant then 1.0 else 0.0

-- | Create regulatory compliance constraint
createComplianceConstraint :: MedicalConstraint
createComplianceConstraint = MedicalConstraint
    { mcId = "COMPLIANCE_C4"
    , mcType = Equality 1.0
    , mcPriority = Critical
    , mcDescription = "Regulatory compliance score must be 1.0 (full compliance)"
    , mcEvaluator = complianceScore
    }

-- | Calculate violation amount for a constraint
constraintViolationAmount :: MedicalConstraint -> Domain -> Double
constraintViolationAmount mc theta =
    let value = mcEvaluator mc theta
    in case mcType mc of
        Equality target -> abs (value - target)
        Inequality minVal -> max 0 (minVal - value)
        Custom predicate -> if predicate theta then 0.0 else 1.0

-- | Check if a constraint is satisfied at a point
satisfiesConstraint :: MedicalConstraint -> Domain -> Bool
satisfiesConstraint mc theta = constraintViolationAmount mc theta < 1e-6

-- | Evaluate a single constraint at a domain point
evaluateConstraint :: MedicalConstraint -> Domain -> ConstraintResult
evaluateConstraint mc theta = 
    let violationAmt = constraintViolationAmount mc theta
        isSatisfied = violationAmt < 1e-6
    in ConstraintResult
        { constraintId = mcId mc
        , satisfied = isSatisfied
        , violation = violationAmt * violationAmt  -- Square for penalty
        }

-- | Check all constraints for a domain point
checkAllConstraints :: [MedicalConstraint] -> Domain -> [ConstraintResult]
checkAllConstraints constraints' theta = map (`evaluateConstraint` theta) constraints'

-- | Check if a set of constraints is satisfiable at a given point
checkConstraintSatisfiability :: [MedicalConstraint] -> Domain -> Bool
checkConstraintSatisfiability constraints' theta =
    all satisfied (checkAllConstraints constraints' theta)

-- | Detect potential conflicts between constraints
-- Returns pairs of conflicting constraint IDs
detectConstraintConflicts :: [MedicalConstraint] -> Domain -> [(String, String)]
detectConstraintConflicts constraints' theta =
    let results = checkAllConstraints constraints' theta
        violated = filter (not . satisfied) results
        -- Create pairs of all violated constraints (potential conflicts)
        pairs = [(constraintId r1, constraintId r2) 
                | r1 <- violated, r2 <- violated, constraintId r1 < constraintId r2]
    in pairs

-- | Check if all constraints can be satisfied simultaneously
-- Returns (all_satisfied, list_of_violations)
checkSimultaneousSatisfaction :: [MedicalConstraint] -> Domain -> (Bool, [String])
checkSimultaneousSatisfaction constraints' theta =
    let results = checkAllConstraints constraints' theta
        allSatisfied = all satisfied results
        violations = [constraintId r | r <- results, not (satisfied r)]
    in (allSatisfied, violations)

-- | Compute combined constraint violation (sum of all violations)
combinedConstraintViolation :: [MedicalConstraint] -> Domain -> Double
combinedConstraintViolation constraints' theta =
    sum $ map violation (checkAllConstraints constraints' theta)
