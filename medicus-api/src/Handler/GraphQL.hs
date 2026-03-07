{-|
Module      : Handler.GraphQL
Description : GraphQL endpoint handler
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

GraphQL endpoint handler using Morpheus GraphQL.
Handles GraphQL queries and mutations.
-}

{-# LANGUAGE OverloadedStrings #-}

module Handler.GraphQL
    ( postGraphQLR
    ) where

import Import
import Data.Morpheus (interpreter)
import qualified Data.ByteString.Lazy as LBS
import qualified Data.Aeson as A
import Control.Monad (when)
import GraphQL.Resolvers (rootResolver)
import qualified Data.Text as T
import Network.HTTP.Types (status400)
import Data.Conduit (($$))
import qualified Data.Conduit.List as CL

-- | GraphQL endpoint handler (POST)
postGraphQLR :: Handler Value
postGraphQLR = do
    -- Add CORS headers
    app <- getYesod
    let cors = appCORS (appSettings app)
    when (corsEnabled cors) $ do
        addHeader "Access-Control-Allow-Origin" "*"
        addHeader "Access-Control-Allow-Methods" "GET, POST, OPTIONS"
        addHeader "Access-Control-Allow-Headers" "Content-Type"
    
    -- Get request body using conduit
    bodyChunks <- rawRequestBody $$ CL.consume
    let body = LBS.fromChunks bodyChunks
    
    -- Execute GraphQL query with interpreter
    result <- liftIO $ interpreter rootResolver body
    
    -- Parse result
    case A.eitherDecode result of
        Left err -> do
            $logError $ "Failed to decode GraphQL result: " <> T.pack err
            sendResponseStatus status400 $ object
                [ "errors" .= [object
                    [ "message" .= ("Internal server error" :: Text)
                    ]]
                ]
        Right value -> return value
