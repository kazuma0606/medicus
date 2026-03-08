{-# LANGUAGE OverloadedStrings #-}

module Util.ErrorSpec (spec) where

import Test.Hspec
import Data.Text (Text)
import qualified Data.Text as T

import Util.Error
import GraphQL.Types.Error (ValidationError(..), ErrorCode(..))

spec :: Spec
spec = do
    describe "Validation Helpers" $ do
        describe "validateDimensionRange" $ do
            it "accepts positive dimensions" $ do
                validateDimensionRange 1 `shouldBe` Nothing
                validateDimensionRange 5 `shouldBe` Nothing
                validateDimensionRange 100 `shouldBe` Nothing
            
            it "rejects zero dimension" $ do
                case validateDimensionRange 0 of
                    Just err -> do
                        errorCode err `shouldBe` InvalidDimension
                        field err `shouldBe` "dimension"
                    Nothing -> expectationFailure "Expected validation error"
            
            it "rejects negative dimensions" $ do
                case validateDimensionRange (-1) of
                    Just err -> errorCode err `shouldBe` InvalidDimension
                    Nothing -> expectationFailure "Expected validation error"
            
            it "rejects very large dimensions" $ do
                case validateDimensionRange 1001 of
                    Just err -> do
                        errorCode err `shouldBe` InvalidDimension
                        field err `shouldBe` "dimension"
                    Nothing -> expectationFailure "Expected validation error"
        
        describe "validateNormWeightsSum" $ do
            it "accepts weights that sum to 1.0" $ do
                validateNormWeightsSum 0.3 0.5 0.2 `shouldBe` Nothing
                validateNormWeightsSum 0.333 0.333 0.334 `shouldBe` Nothing
                validateNormWeightsSum 1.0 0.0 0.0 `shouldBe` Nothing
            
            it "rejects weights that don't sum to 1.0" $ do
                case validateNormWeightsSum 0.3 0.3 0.3 of
                    Just err -> do
                        errorCode err `shouldBe` InvalidNormWeights
                        field err `shouldBe` "normWeights"
                    Nothing -> expectationFailure "Expected validation error"
            
            it "rejects negative weights" $ do
                case validateNormWeightsSum (-0.1) 0.6 0.5 of
                    Just err -> do
                        errorCode err `shouldBe` InvalidNormWeights
                        errorMessage err `shouldSatisfy` T.isInfixOf "non-negative"
                    Nothing -> expectationFailure "Expected validation error"
            
            it "handles floating point precision" $ do
                -- 0.1 + 0.2 + 0.7 might not be exactly 1.0 due to floating point
                validateNormWeightsSum 0.1 0.2 0.7 `shouldBe` Nothing
        
        describe "validateConstraintDimensions" $ do
            it "accepts valid constraint dimensions" $ do
                validateConstraintDimensions 5 [0, 1, 2] `shouldBe` Nothing
                validateConstraintDimensions 10 [0] `shouldBe` Nothing
                validateConstraintDimensions 3 [0, 1, 2] `shouldBe` Nothing
            
            it "rejects empty constraint dimensions" $ do
                case validateConstraintDimensions 5 [] of
                    Just err -> do
                        errorCode err `shouldBe` InvalidConstraint
                        field err `shouldBe` "constraints.dimensions"
                    Nothing -> expectationFailure "Expected validation error"
            
            it "rejects negative dimension indices" $ do
                case validateConstraintDimensions 5 [0, -1, 2] of
                    Just err -> do
                        errorCode err `shouldBe` InvalidConstraint
                        errorMessage err `shouldSatisfy` T.isInfixOf "non-negative"
                    Nothing -> expectationFailure "Expected validation error"
            
            it "rejects dimension indices >= space dimension" $ do
                case validateConstraintDimensions 5 [0, 5, 2] of
                    Just err -> do
                        errorCode err `shouldBe` InvalidDimension
                        field err `shouldBe` "constraints.dimensions"
                    Nothing -> expectationFailure "Expected validation error"
            
            it "rejects all dimension indices >= space dimension" $ do
                case validateConstraintDimensions 3 [3, 4, 5] of
                    Just err -> errorCode err `shouldBe` InvalidDimension
                    Nothing -> expectationFailure "Expected validation error"
    
    describe "Error Code Mapping" $ do
        it "maps MEDICUS error codes to GraphQL error codes" $ do
            mapMEDICUSErrorCode "invalid_dimension" `shouldBe` "INVALID_DIMENSION"
            mapMEDICUSErrorCode "invalid_norm_weights" `shouldBe` "INVALID_NORM_WEIGHTS"
            mapMEDICUSErrorCode "invalid_constraint" `shouldBe` "INVALID_CONSTRAINT"
            mapMEDICUSErrorCode "optimization_failed" `shouldBe` "OPTIMIZATION_FAILED"
            mapMEDICUSErrorCode "convergence_failed" `shouldBe` "CONVERGENCE_FAILED"
        
        it "handles unknown error codes" $ do
            let result = mapMEDICUSErrorCode "some_unknown_error"
            result `shouldSatisfy` T.isPrefixOf "UNKNOWN_ERROR_"
    
    describe "Error Message Formatting" $ do
        it "formats dimension errors" $ do
            let err = MEDICUSInvalidDimension "must be positive"
            let formatted = formatMEDICUSError err
            formatted `shouldSatisfy` T.isInfixOf "Invalid dimension"
            formatted `shouldSatisfy` T.isInfixOf "must be positive"
        
        it "formats norm weight errors" $ do
            let err = MEDICUSInvalidNormWeights "sum must be 1.0"
            let formatted = formatMEDICUSError err
            formatted `shouldSatisfy` T.isInfixOf "Invalid norm weights"
        
        it "formats constraint errors" $ do
            let err = MEDICUSInvalidConstraint "threshold out of range"
            let formatted = formatMEDICUSError err
            formatted `shouldSatisfy` T.isInfixOf "Invalid constraint"
        
        it "formats optimization errors" $ do
            let err = MEDICUSOptimizationFailed "maximum iterations reached"
            let formatted = formatMEDICUSError err
            formatted `shouldSatisfy` T.isInfixOf "Optimization failed"
    
    describe "GraphQL Error Conversion" $ do
        it "converts dimension error to GraphQL error" $ do
            let medicusErr = MEDICUSInvalidDimension "must be positive"
            let graphqlErr = toGraphQLValidationError medicusErr
            
            field graphqlErr `shouldBe` "dimension"
            errorCode graphqlErr `shouldBe` InvalidDimension
            errorMessage graphqlErr `shouldBe` "must be positive"
        
        it "converts multiple errors" $ do
            let medicusErrs = 
                    [ MEDICUSInvalidDimension "must be positive"
                    , MEDICUSInvalidNormWeights "sum must be 1.0"
                    ]
            let graphqlErrs = toGraphQLValidationErrors medicusErrs
            
            length graphqlErrs `shouldBe` 2
            errorCode (head graphqlErrs) `shouldBe` InvalidDimension
            errorCode (graphqlErrs !! 1) `shouldBe` InvalidNormWeights
        
        it "converts convergence failure" $ do
            let medicusErr = MEDICUSConvergenceFailed "did not converge in 1000 iterations"
            let graphqlErr = toGraphQLValidationError medicusErr
            
            field graphqlErr `shouldBe` "optimization"
            errorCode graphqlErr `shouldBe` ConvergenceFailure
    
    describe "Edge Cases" $ do
        it "handles empty error list" $ do
            let errs = toGraphQLValidationErrors []
            errs `shouldBe` []
        
        it "handles unknown error type" $ do
            let medicusErr = MEDICUSUnknownError "something went wrong"
            let graphqlErr = toGraphQLValidationError medicusErr
            
            errorCode graphqlErr `shouldBe` InternalError
            field graphqlErr `shouldBe` "unknown"
        
        it "handles very large dimension" $ do
            case validateDimensionRange 10000 of
                Just err -> errorCode err `shouldBe` InvalidDimension
                Nothing -> expectationFailure "Expected validation error"
        
        it "handles dimension exactly at boundary" $ do
            validateDimensionRange 1000 `shouldBe` Nothing
            
            case validateDimensionRange 1001 of
                Just err -> errorCode err `shouldBe` InvalidDimension
                Nothing -> expectationFailure "Expected validation error"
