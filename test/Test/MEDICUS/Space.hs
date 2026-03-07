{-|
Module      : Test.MEDICUS.Space
Description : Tests for MEDICUS Space operations
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
-}

module Test.MEDICUS.Space (tests) where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import qualified Data.Vector.Storable as V

import MEDICUS.Space.Core
import MEDICUS.Space.Types
import Test.MEDICUS.Generators

tests :: TestTree
tests = testGroup "Space Operations"
    [ unitTests
    , propertyTests
    , helperFunctionTests
    ]

unitTests :: TestTree
unitTests = testGroup "Unit Tests"
    [ testCase "Default MEDICUS space creation" $
        spaceDimension defaultMedicusSpace @?= 3
    
    , testCase "Default norm weights" $
        lambda defaultNormWeights @?= 1.0
    
    , testCase "Default domain bounds" $
        defaultDomainBounds @?= [(0, 1), (0, 1), (0, 1)]
    
    , testCase "Constant function evaluation" $
        let f = constantFunction 5.0
            theta = domainZero 3
            result = applyFunction (mfFunction f) theta
        in result @?= 5.0
    
    , testCase "Linear function evaluation at zero" $
        let coeffs = V.fromList [1.0, 2.0, 3.0]
            f = linearFunction coeffs 4.0
            theta = domainZero 3
            result = applyFunction (mfFunction f) theta
        in result @?= 4.0  -- Intercept only
    
    , testCase "Quadratic function at zero" $
        let coeffs = V.fromList [1.0, 2.0, 3.0]
            f = quadraticFunction coeffs
            theta = domainZero 3
            result = applyFunction (mfFunction f) theta
        in result @?= 0.0
    ]

propertyTests :: TestTree
propertyTests = testGroup "Property Tests"
    [ testProperty "Space dimension is positive" $
        forAll genSmallDimension $ \dim ->
            spaceDimension (createMedicusSpace dim [] [] defaultNormWeights 1e-6) === dim
    
    , testProperty "Created space preserves bounds" $
        forAll genSmallDimension $ \dim ->
        forAll (genDomainBounds dim) $ \bounds ->
            let space = createMedicusSpace dim bounds [] defaultNormWeights 1e-6
            in domainBounds space === bounds
    ]

helperFunctionTests :: TestTree
helperFunctionTests = testGroup "Helper Function Tests"
    [ testCase "domainZero creates zero vector" $
        V.toList (domainZero 3) @?= [0.0, 0.0, 0.0]
    
    , testCase "domainFromList converts correctly" $
        V.toList (domainFromList [1.0, 2.0, 3.0]) @?= [1.0, 2.0, 3.0]
    
    , testCase "domainDimension returns correct size" $
        domainDimension (domainFromList [1.0, 2.0, 3.0]) @?= 3
    
    , testCase "inDomainBounds accepts point inside" $
        let bounds = [(0, 1), (0, 1), (0, 1)]
            point = domainFromList [0.5, 0.5, 0.5]
        in inDomainBounds bounds point @?= True
    
    , testCase "inDomainBounds rejects point outside" $
        let bounds = [(0, 1), (0, 1), (0, 1)]
            point = domainFromList [1.5, 0.5, 0.5]
        in inDomainBounds bounds point @?= False
    ]
