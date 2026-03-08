{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

{- |
Module      : Integration.E2ESpec
Description : End-to-End integration tests for MEDICUS API
Copyright   : (c) MEDICUS Project, 2026
License     : Proprietary
Maintainer  : medicus@example.com
-}

module Integration.E2ESpec (spec) where

import Test.Hspec
import Yesod.Test
import Data.Aeson (encode, object, (.=))
import qualified Data.ByteString.Lazy.Char8 as LBS
import Network.HTTP.Types (status200)

import Application (makeFoundation)
import Settings (loadSettings)
import Foundation (App)

-- | Setup foundation for testing
withApp :: SpecWith (TestApp App) -> Spec
withApp = before $ do
    settings <- loadSettings
    foundation <- makeFoundation settings
    return (foundation, id)

spec :: Spec
spec = withApp $ do
    describe "System Health" $ do
        it "responds to health check endpoint" $ do
            get HealthR
            statusIs 200
            bodyContains "healthy"
            bodyContains "medicus-api"

    describe "GraphQL API End-to-End" $ do
        describe "Query: health" $ do
            it "returns healthy status via GraphQL" $ do
                let gqlQuery = object [ "query" .= ("query { health { status version } }" :: String) ]
                post GraphQLR (encode gqlQuery)
                statusIs 200
                bodyContains "healthy"

        describe "Query: listAvailableConstraints" $ do
            it "returns list of constraints" $ do
                let gqlQuery = object [ "query" .= ("query { listAvailableConstraints }" :: String) ]
                post GraphQLR (encode gqlQuery)
                statusIs 200
                bodyContains "PrivacyProtection"
                bodyContains "EmergencyAccess"

        describe "Mutation: createSpace" $ do
            it "successfully creates a new space" $ do
                let gqlQuery = object 
                        [ "query" .= ("mutation { createSpace(csConfig: { dimension: 2, normWeights: { lambda: 0.5, mu: 0.5, nu: 0.0 }, constraints: [] }) { spaceId success } }" :: String)
                        ]
                post GraphQLR (encode gqlQuery)
                statusIs 200
                bodyContains "\"success\":true"
                bodyContains "temp-space-id"

        describe "Mutation: optimize" $ do
            it "executes optimization through the full stack" $ do
                let gqlQuery = object 
                        [ "query" .= ("mutation { optimize(input: { objective: { functionType: Quadratic, parameters: \"{}\" }, initialPoint: [0.0, 0.0] }) { success solution } }" :: String)
                        ]
                post GraphQLR (encode gqlQuery)
                statusIs 200
                bodyContains "solution"
                bodyContains "success"

    describe "Error Scenarios" $ do
        it "returns validation errors for invalid space config" $ do
            let gqlQuery = object 
                    [ "query" .= ("query { validateSpace(config: { dimension: -1, normWeights: { lambda: 1.0, mu: 1.0, nu: 1.0 }, constraints: [] }) { valid errors { errorCode } } }" :: String)
                    ]
            post GraphQLR (encode gqlQuery)
            statusIs 200
            bodyContains "\"valid\":false"
            bodyContains "InvalidDimension"
            bodyContains "InvalidNormWeights"
