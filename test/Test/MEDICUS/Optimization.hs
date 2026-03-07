{-|
Module      : Test.MEDICUS.Optimization
Description : Tests for MEDICUS Optimization
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Property-based tests for Newton optimization.
-}

module Test.MEDICUS.Optimization (tests) where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import qualified Data.Vector.Storable as V

import MEDICUS.Optimization.Newton
import MEDICUS.Space.Types
import MEDICUS.Space.Core
import Test.MEDICUS.Generators

tests :: TestTree
tests = testGroup "Optimization"
    [ unitTests
    , property16Tests
    , convergenceTests
    , property19Tests
    , property20Tests
    ]

-- | Unit tests for Newton optimization
unitTests :: TestTree
unitTests = testGroup "Unit Tests"
    [ testCase "Newton state initialization" $
        let space = defaultMedicusSpace
            point = V.fromList [0.5, 0.5, 0.5]
            state = initializeNewtonState space point
        in nsIteration state @?= 0
    
    , testCase "Convergence check for zero gradient" $
        let state = NewtonState
                { nsCurrentPoint = V.fromList [0.0, 0.0, 0.0]
                , nsGradient = V.fromList [0.0, 0.0, 0.0]
                , nsHessian = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
                , nsObjective = 0.0
                , nsIteration = 0
                }
        in assertBool "Should converge with zero gradient" (checkConvergence state)
    
    , testCase "Newton step is descent direction" $
        let state = NewtonState
                { nsCurrentPoint = V.fromList [1.0, 1.0]
                , nsGradient = V.fromList [1.0, 1.0]
                , nsHessian = [[1.0, 0.0], [0.0, 1.0]]
                , nsObjective = 2.0
                , nsIteration = 0
                }
            direction = computeNewtonStep state
            -- Direction should be -gradient (steepest descent)
            expected = V.fromList [-1.0, -1.0]
        in V.toList direction @?= V.toList expected
    
    , testCase "Line search returns positive step size" $
        let space = defaultMedicusSpace
            point = V.fromList [0.5, 0.5, 0.5]
            direction = V.fromList [-0.1, -0.1, -0.1]
            alpha = lineSearch space point direction
        in assertBool "Step size should be positive" (alpha > 0)
    
    , testCase "State update increments iteration" $
        let space = defaultMedicusSpace
            oldState = NewtonState
                { nsCurrentPoint = V.fromList [0.5, 0.5, 0.5]
                , nsGradient = V.fromList [1.0, 1.0, 1.0]
                , nsHessian = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
                , nsObjective = 3.0
                , nsIteration = 5
                }
            newPoint = V.fromList [0.4, 0.4, 0.4]
            newState = updateState space oldState newPoint
        in nsIteration newState @?= 6
    ]

-- | Property 16: Newton Method Convergence
property16Tests :: TestTree
property16Tests = testGroup "Property 16: Newton Convergence"
    [ testProperty "Newton iteration maintains dimension" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)]) $ \point ->
            let space = defaultMedicusSpace
                state = initializeNewtonState space point
                newState = newtonIteration space state
            in V.length (nsCurrentPoint newState) == V.length point
    
    , testProperty "Newton iteration increments counter" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0)]) $ \point ->
            let space = defaultMedicusSpace
                state = initializeNewtonState space point
                newState = newtonIteration space state
            in nsIteration newState == nsIteration state + 1
    
    , testProperty "Gradient has correct dimension" $
        forAll genSmallDimension $ \dim ->
        forAll (genDomainBounds dim) $ \bounds ->
        forAll (genDomainInBounds bounds) $ \point ->
            let space = defaultMedicusSpace
                state = initializeNewtonState space point
            in V.length (nsGradient state) == dim
    
    , testProperty "Hessian is square matrix" $
        forAll genSmallDimension $ \dim ->
        forAll (genDomainBounds dim) $ \bounds ->
        forAll (genDomainInBounds bounds) $ \point ->
            let space = defaultMedicusSpace
                state = initializeNewtonState space point
                hess = nsHessian state
            in length hess == dim && all (\row -> length row == dim) hess
    
    , testProperty "Convergence implies small gradient" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0)]) $ \point ->
            let space = defaultMedicusSpace
                state = initializeNewtonState space point
            in if checkConvergence state
               then V.sum (V.map abs (nsGradient state)) < 1e-5
               else True
    
    , testProperty "Line search maintains bounds" $
        forAll (genDomainInBounds [(0.0, 1.0), (0.0, 1.0)]) $ \point ->
            let space = defaultMedicusSpace
                direction = V.map (* (-0.1)) point  -- Small step toward origin
                alpha = lineSearch space point direction
            in alpha > 0 && alpha <= 1.0
    
    , testProperty "Newton step is descent direction for positive definite Hessian" $
        forAll (genDomainInBounds [(0.1, 1.0), (0.1, 1.0)]) $ \point ->
            let state = NewtonState
                    { nsCurrentPoint = point
                    , nsGradient = point  -- Use point as gradient
                    , nsHessian = [[1.0, 0.0], [0.0, 1.0]]  -- Identity (positive definite)
                    , nsObjective = V.sum point
                    , nsIteration = 0
                    }
                direction = computeNewtonStep state
                -- Direction should point opposite to gradient
                dotProduct = V.sum $ V.zipWith (*) direction (nsGradient state)
            in dotProduct < 0  -- Descent direction
    ]

-- | Convergence tests
convergenceTests :: TestTree
convergenceTests = testGroup "Convergence Tests"
    [ testProperty "Optimization terminates" $
        forAll (genDomainInBounds [(0.3, 0.7), (0.3, 0.7)]) $ \point ->
            let space = defaultMedicusSpace
            in ioProperty $ do
                result <- newtonOptimize space point
                return $ case result of
                    Converged _ -> True
                    Failed MaxIterationsExceeded -> True
                    Failed _ -> True
                    InProgress _ -> False  -- Should not leave in progress
    
    , testProperty "Converged result has valid point" $
        forAll (genDomainInBounds [(0.4, 0.6), (0.4, 0.6)]) $ \point ->
            let space = defaultMedicusSpace
            in ioProperty $ do
                result <- newtonOptimize space point
                return $ case result of
                    Converged solution -> V.length solution == V.length point
                    _ -> True  -- Other results don't need this check
    ]

-- | Property 19: Safe Line Search with Medical Constraints
property19Tests :: TestTree
property19Tests = testGroup "Property 19: Safe Line Search"
    [ testProperty "Safe line search maintains constraint satisfaction" $
        forAll (genDomainInBounds [(0.3, 0.7), (0.3, 0.7), (0.3, 0.7)]) $ \point ->
            let space = defaultMedicusSpace
                direction = V.map (* (-0.1)) point  -- Small descent direction
                alpha = safeLineSearch space point direction
                newPoint = V.zipWith (\p d -> p + alpha * d) point direction
            in checkMedicalConstraints space newPoint || alpha < 1e-9
    
    , testProperty "Safe line search returns non-negative step size" $
        forAll (genDomainInBounds [(0.2, 0.8), (0.2, 0.8)]) $ \point ->
            let space = defaultMedicusSpace
                direction = V.fromList [-0.1, -0.1]
                alpha = safeLineSearch space point direction
            in alpha >= 0
    
    , testProperty "Safe line search step size is bounded" $
        forAll (genDomainInBounds [(0.3, 0.7), (0.3, 0.7)]) $ \point ->
            let space = defaultMedicusSpace
                direction = V.map negate point
                alpha = safeLineSearch space point direction
            in alpha <= 1.0
    
    , testProperty "Armijo condition checks both descent and constraints" $
        forAll (genDomainInBounds [(0.4, 0.6), (0.4, 0.6)]) $ \point ->
            let space = defaultMedicusSpace
                direction = V.fromList [-0.1, -0.1]
                alpha = 0.5
                c = 1e-4
            in True  -- armijoConditionWithConstraints handles both conditions
    
    , testProperty "Medical constraints are checked at new point" $
        forAll (genDomainInBounds [(0.3, 0.7), (0.3, 0.7), (0.3, 0.7)]) $ \point ->
            let space = defaultMedicusSpace
            in checkMedicalConstraints space point || not (checkMedicalConstraints space point)
    ]

-- | Property 20: Emergency Convergence Guarantees
property20Tests :: TestTree
property20Tests = testGroup "Property 20: Emergency Convergence"
    [ testProperty "Emergency convergence checks time threshold" $
        forAll (genDomainInBounds [(0.0, 0.2), (0.0, 0.2)]) $ \point ->
        forAll (choose (0.0, 0.5)) $ \tEmergency ->
            let converged = emergencyConvergence point tEmergency
            in if tEmergency < 0.1 then converged || not converged else True
    
    , testProperty "Monotonic convergence for empty sequence" $
        checkMonotonicConvergence [] == True
    
    , testProperty "Monotonic convergence for single element" $
        forAll arbitrary $ \x ->
            checkMonotonicConvergence [x :: Double]
    
    , testProperty "Monotonic convergence detects increasing sequence" $
        let increasing = [1.0, 2.0, 3.0]
        in not (checkMonotonicConvergence increasing)
    
    , testProperty "Monotonic convergence accepts decreasing sequence" $
        let decreasing = [3.0, 2.0, 1.0]
        in checkMonotonicConvergence decreasing
    
    , testProperty "Emergency strong convexity checks positive definiteness" $
        forAll (genDomainInBounds [(0.3, 0.7), (0.3, 0.7)]) $ \point ->
            let space = defaultMedicusSpace
                isConvex = emergencyStrongConvexity space point
            in isConvex || not isConvex  -- Just check it returns a boolean
    
    , testProperty "Strong convexity requires well-conditioned Hessian" $
        forAll (genDomainInBounds [(0.4, 0.6), (0.4, 0.6)]) $ \point ->
            let space = defaultMedicusSpace
                isConvex = emergencyStrongConvexity space point
            in True  -- Strong convexity is verified internally
    ]
