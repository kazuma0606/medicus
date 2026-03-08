{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Util.ErrorSpec
Description : Unit tests for Error Conversion Utilities
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module Util.ErrorSpec (spec) where

import Test.Hspec
import qualified Data.Text as T
import Util.Error
import GraphQL.Types.Error (ValidationError(..), ErrorCode(..))
import qualified MEDICUS.API as MA

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
        
        describe "validateConstraintDimensions" $ do
            it "accepts valid constraint dimensions" $ do
                validateConstraintDimensions 5 [0, 1, 2] `shouldBe` Nothing
                validateConstraintDimensions 10 [0] `shouldBe` Nothing
            
            it "rejects empty constraint dimensions" $ do
                case validateConstraintDimensions 5 [] of
                    Just err -> errorCode err `shouldBe` InvalidConstraint
                    Nothing -> expectationFailure "Expected validation error"
    
    describe "Error Code Mapping" $ do
        it "maps MEDICUS error codes to GraphQL error codes" $ do
            mapMEDICUSErrorCode "invalid_dimension" `shouldBe` "INVALID_DIMENSION"
            mapMEDICUSErrorCode "invalid_norm_weights" `shouldBe` "INVALID_NORM_WEIGHTS"
            mapMEDICUSErrorCode "invalid_constraint" `shouldBe` "INVALID_CONSTRAINT"
        
        it "handles unknown error codes" $ do
            let result = mapMEDICUSErrorCode "unknown"
            result `shouldSatisfy` T.isPrefixOf "UNKNOWN_ERROR_"
    
    describe "GraphQL Error Conversion" $ do
        it "converts dimension error to GraphQL error" $ do
            let medicusErr = MA.InvalidDimension 0
            let graphqlErr = toGraphQLValidationError medicusErr
            
            field graphqlErr `shouldBe` "dimension"
            errorCode graphqlErr `shouldBe` InvalidDimension
            errorMessage graphqlErr `shouldSatisfy` T.isInfixOf "0"
        
        it "converts constraint violation error" $ do
            let medicusErr = MA.ConstraintViolation "Privacy violated"
            let graphqlErr = toGraphQLValidationError medicusErr
            
            field graphqlErr `shouldBe` "constraints"
            errorCode graphqlErr `shouldBe` InvalidConstraint
            errorMessage graphqlErr `shouldBe` "Privacy violated"
        
        it "converts multiple errors" $ do
            let medicusErrs = [MA.InvalidDimension 0, MA.BoundsMismatch]
            let graphqlErrs = toGraphQLValidationErrors medicusErrs
            length graphqlErrs `shouldBe` 2

    describe "API Error Helpers" $ do
        it "provides helpful suggestions for common errors" $ do
            let suggestions = getErrorSuggestions InvalidDimension
            length suggestions `shouldSatisfy` (> 0)
            head suggestions `shouldSatisfy` T.isInfixOf "dimension"
            
            let suggestions' = getErrorSuggestions ConvergenceFailure
            length suggestions' `shouldSatisfy` (> 0)
            
        it "creates structured APIError objects" $ do
            let apiErr = makeAPIError "Something went wrong" InternalError
            GraphQL.Types.Error.message apiErr `shouldBe` "Something went wrong"
            code apiErr `shouldBe` InternalError
            length (suggestions apiErr) `shouldSatisfy` (> 0)
