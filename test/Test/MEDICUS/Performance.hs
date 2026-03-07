{-|
Module      : Test.MEDICUS.Performance
Description : Performance optimization property tests
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause
Maintainer  : medicus@example.com

Tests for performance optimization features (Property 45).
-}

module Test.MEDICUS.Performance (tests) where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import MEDICUS.API
import MEDICUS.Space.Types
import MEDICUS.Space.Core (defaultMedicusSpace)
import qualified Data.Vector.Storable as V

-- | Test generators
genDomainList :: Int -> Int -> Gen [Domain]
genDomainList dim count = do
    vectorOf count (V.fromList <$> vectorOf dim (choose (-10.0, 10.0)))

genMedicusFunction :: Gen MedicusFunction
genMedicusFunction = do
    return $ MedicusFunction
        { mfFunction = MedicalFunction $ \v -> V.sum v
        , mfGradient = \_ -> V.replicate 3 1.0
        , mfHessian = \_ -> replicate 3 (replicate 3 0.0)
        , mfConstraints = []
        }

-- | All tests
tests :: TestTree
tests = testGroup "Performance"
    [ unitTests
    , property45Tests
    ]

-- | Unit tests
unitTests :: TestTree
unitTests = testGroup "Unit Tests"
    [ testCase "Parallel evaluate returns correct length" $ do
        let f = MedicusFunction
                { mfFunction = MedicalFunction $ \v -> V.sum v
                , mfGradient = \_ -> V.replicate 3 1.0
                , mfHessian = \_ -> replicate 3 (replicate 3 0.0)
                , mfConstraints = []
                }
            points = [V.fromList [1,2,3], V.fromList [4,5,6]]
            results = parallelEvaluate f points
        length results @?= length points
    
    , testCase "Batch process executes all operations" $ do
        let space = defaultMedicusSpace
            ops = [const (1::Int), const (2::Int), const (3::Int)]
            results = batchProcess ops space
        length results @?= length ops
    
    , testCase "Parallel evaluate produces same results as sequential" $ do
        let f = MedicusFunction
                { mfFunction = MedicalFunction $ \v -> V.sum v
                , mfGradient = \_ -> V.replicate 3 1.0
                , mfHessian = \_ -> replicate 3 (replicate 3 0.0)
                , mfConstraints = []
                }
            point = V.fromList [1.0, 2.0, 3.0]
            parallel = head $ parallelEvaluate f [point]
            sequential = applyFunction (mfFunction f) point
        parallel @?= sequential
    
    , testCase "Batch process maintains order" $ do
        let space = defaultMedicusSpace
            ops = [const (1::Int), const (2::Int), const (3::Int)]
            results = batchProcess ops space
        results @?= [1, 2, 3]
    
    , testCase "Empty parallel evaluate returns empty list" $ do
        let f = MedicusFunction
                { mfFunction = MedicalFunction $ \v -> V.sum v
                , mfGradient = \_ -> V.replicate 3 1.0
                , mfHessian = \_ -> replicate 3 (replicate 3 0.0)
                , mfConstraints = []
                }
            results = parallelEvaluate f []
        results @?= []
    
    , testCase "Empty batch process returns empty list" $ do
        let space = defaultMedicusSpace
            results = batchProcess ([] :: [MedicusSpace -> Int]) space
        results @?= []
    ]

-- | Property 45: Performance Optimization
property45Tests :: TestTree
property45Tests = testGroup "Property 45: Performance Optimization"
    [ testProperty "Parallel evaluate preserves length" $
        forAll (choose (1, 10)) $ \count ->
        forAll (genDomainList 3 count) $ \points ->
        forAll genMedicusFunction $ \f ->
            let results = parallelEvaluate f points
            in length results == length points
    
    , testProperty "Parallel evaluate produces finite results" $
        forAll (genDomainList 3 5) $ \points ->
        forAll genMedicusFunction $ \f ->
            let results = parallelEvaluate f points
            in all (\r -> not (isNaN r) && not (isInfinite r)) results
    
    , testProperty "Batch process preserves operation count" $
        forAll (choose (1, 10)) $ \count ->
            let space = defaultMedicusSpace
                ops = replicate count (const (1::Int))
                results = batchProcess ops space
            in length results == count
    
    , testProperty "Batch process applies all operations" $
        forAll (vectorOf 5 (choose (1, 10))) $ \values ->
            let space = defaultMedicusSpace
                ops = map const (values :: [Int])
                results = batchProcess ops space
            in results == values
    
    , testProperty "Parallel evaluate is consistent" $
        forAll (genDomainList 3 3) $ \points ->
        forAll genMedicusFunction $ \f ->
            let results1 = parallelEvaluate f points
                results2 = parallelEvaluate f points
            in results1 == results2
    
    , testProperty "Parallel evaluate handles single point" $
        forAll (V.fromList <$> vectorOf 3 (choose (-10.0, 10.0))) $ \point ->
        forAll genMedicusFunction $ \f ->
            let results = parallelEvaluate f [point]
            in length results == 1
    
    , testProperty "Batch process is deterministic" $
        forAll (vectorOf 5 (choose (1, 10))) $ \values ->
            let space = defaultMedicusSpace
                ops = map const (values :: [Int])
                results1 = batchProcess ops space
                results2 = batchProcess ops space
            in results1 == results2
    
    , testProperty "Empty inputs produce empty outputs" $
        forAll genMedicusFunction $ \f ->
            let parallelResults = parallelEvaluate f []
                space = defaultMedicusSpace
                batchResults = batchProcess ([] :: [MedicusSpace -> Int]) space
            in null parallelResults && null batchResults
    ]
