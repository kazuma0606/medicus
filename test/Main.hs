{-|
Module      : Main
Description : Test suite entry point for MEDICUS Engine
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Main test suite runner using Tasty framework.
-}

module Main (main) where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck as QC

import qualified Test.MEDICUS.Space as Space
import qualified Test.MEDICUS.Norm as Norm
import qualified Test.MEDICUS.Constraints as Constraints
import qualified Test.MEDICUS.Properties as Properties
import qualified Test.MEDICUS.Optimization as Optimization
import qualified Test.MEDICUS.Mollifier as Mollifier
import qualified Test.MEDICUS.StatisticalMechanics as StatisticalMechanics
import qualified Test.MEDICUS.UncertaintyPrinciple as UncertaintyPrinciple
import qualified Test.MEDICUS.EntropyManagement as EntropyManagement
import qualified Test.MEDICUS.PropertyVerification as PropertyVerification
import qualified Test.MEDICUS.Performance as Performance

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "MEDICUS Engine Tests"
    [ spaceTests
    , normTests
    , constraintTests
    , optimizationTests
    , mollifierTests
    , statisticalMechanicsTests
    , uncertaintyPrincipleTests
    , entropyManagementTests
    , propertyVerificationTests
    , performanceTests
    , propertyTests
    ]

spaceTests :: TestTree
spaceTests = testGroup "MEDICUS Space Tests"
    [ Space.tests
    ]

normTests :: TestTree
normTests = testGroup "MEDICUS Norm Tests"
    [ Norm.tests
    ]

constraintTests :: TestTree
constraintTests = testGroup "Medical Constraint Tests"
    [ Constraints.tests
    ]

optimizationTests :: TestTree
optimizationTests = testGroup "Optimization Tests"
    [ Optimization.tests
    ]

mollifierTests :: TestTree
mollifierTests = testGroup "Mollifier Tests"
    [ Mollifier.tests
    ]

statisticalMechanicsTests :: TestTree
statisticalMechanicsTests = testGroup "Statistical Mechanics Tests"
    [ StatisticalMechanics.tests
    ]

uncertaintyPrincipleTests :: TestTree
uncertaintyPrincipleTests = testGroup "Uncertainty Principle Tests"
    [ UncertaintyPrinciple.tests
    ]

entropyManagementTests :: TestTree
entropyManagementTests = testGroup "Entropy Management Tests"
    [ EntropyManagement.tests
    ]

propertyVerificationTests :: TestTree
propertyVerificationTests = testGroup "Property Verification Tests"
    [ PropertyVerification.tests
    ]

performanceTests :: TestTree
performanceTests = testGroup "Performance Tests"
    [ Performance.tests
    ]

propertyTests :: TestTree
propertyTests = testGroup "Mathematical Property Tests"
    [ Properties.tests
    ]
