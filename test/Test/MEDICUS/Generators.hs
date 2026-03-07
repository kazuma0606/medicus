{-|
Module      : Test.MEDICUS.Generators
Description : QuickCheck generators for MEDICUS types
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

QuickCheck Arbitrary instances for generating random MEDICUS types.
-}

module Test.MEDICUS.Generators where

import Test.QuickCheck
import qualified Data.Vector.Storable as V
import MEDICUS.Space.Types
import MEDICUS.Space.Core

-- | Generate a valid dimension (1-10)
genDimension :: Gen Int
genDimension = choose (1, 10)

-- | Generate a positive dimension (used for actual tests)
genSmallDimension :: Gen Int
genSmallDimension = choose (1, 5)

-- | Generate domain bounds for given dimension
genDomainBounds :: Int -> Gen DomainBounds
genDomainBounds n = vectorOf n genBoundPair
  where
    genBoundPair = do
        lo <- choose (-10.0, 10.0)
        hi <- choose (lo, lo + 20.0)  -- Ensure hi > lo
        return (lo, hi)

-- | Generate a domain point within bounds
genDomainInBounds :: DomainBounds -> Gen Domain
genDomainInBounds bounds = do
    values <- mapM genInRange bounds
    return $ V.fromList values
  where
    genInRange (lo, hi) = choose (lo, hi)

-- | Generate norm weights with positive values
genNormWeights :: Gen NormWeights
genNormWeights = do
    l <- choose (0.1, 10.0)
    m <- choose (0.1, 10.0)
    n <- choose (0.1, 10.0)
    return $ NormWeights l m n

-- | Generate a valid tolerance value
genTolerance :: Gen Double
genTolerance = choose (1e-10, 1e-3)

-- | Arbitrary instance for NormWeights
instance Arbitrary NormWeights where
    arbitrary = genNormWeights
    shrink (NormWeights l m n) = 
        [ NormWeights l' m' n' 
        | l' <- shrinkPositive l
        , m' <- shrinkPositive m
        , n' <- shrinkPositive n
        , l' > 0, m' > 0, n' > 0
        ]
      where
        shrinkPositive x = filter (> 0) $ shrink x

-- | Arbitrary instance for ConstraintPriority
instance Arbitrary ConstraintPriority where
    arbitrary = elements [Critical, Important, Preferred]

-- | Generate a simple MEDICUS space for testing
genSimpleMedicusSpace :: Gen MedicusSpace
genSimpleMedicusSpace = do
    dim <- genSmallDimension
    bounds <- genDomainBounds dim
    weights <- genNormWeights
    tol <- genTolerance
    return $ createMedicusSpace dim bounds [] weights tol

-- | Generate a MEDICUS space with specific dimension
genMedicusSpaceWithDim :: Int -> Gen MedicusSpace
genMedicusSpaceWithDim dim = do
    bounds <- genDomainBounds dim
    weights <- genNormWeights
    tol <- genTolerance
    return $ createMedicusSpace dim bounds [] weights tol

-- | Arbitrary instance for MedicusSpace (without constraints for simplicity)
instance Arbitrary MedicusSpace where
    arbitrary = genSimpleMedicusSpace

-- | Generate a constant medical function
genConstantFunction :: Gen MedicusFunction
genConstantFunction = do
    c <- arbitrary :: Gen Double
    return $ constantFunction c

-- | Generate a linear medical function
genLinearFunction :: Int -> Gen MedicusFunction
genLinearFunction dim = do
    coeffs <- V.replicateM dim (arbitrary :: Gen Double)
    intercept <- arbitrary :: Gen Double
    return $ linearFunction coeffs intercept

-- | Generate a quadratic medical function
genQuadraticFunction :: Int -> Gen MedicusFunction
genQuadraticFunction dim = do
    coeffs <- V.replicateM dim (choose (0.01, 10.0))  -- Positive coefficients
    return $ quadraticFunction coeffs

-- | Generate a simple MEDICUS function
genSimpleMedicusFunction :: Gen MedicusFunction
genSimpleMedicusFunction = oneof
    [ genConstantFunction
    , genLinearFunction 3
    , genQuadraticFunction 3
    ]
