{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE OverloadedStrings #-}

{- |
Module      : Application
Description : Application initialization and middleware setup
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

This module provides the entry points for creating the WAI application,
setting up the foundation data structure, and configuring logging middleware.
-}

module Application
    ( -- * Application Creation
      makeApplication
    , makeFoundation
    , makeLogWare
    ) where

import Foundation
import Settings
import Handler.Health
import Handler.GraphQL
import Handler.Playground

import Yesod.Core
import Network.Wai (Middleware, Application)
import Data.Default (def)
import Network.Wai.Handler.Warp (setPort)
import Network.Wai.Middleware.RequestLogger
    ( Destination(..)
    , IPAddrSource(..)
    , OutputFormat(..)
    , destination
    , mkRequestLogger
    , outputFormat
    )
import System.Log.FastLogger
    ( defaultBufSize
    , newStdoutLoggerSet
    , toLogStr
    )
import Data.Aeson (object, (.=), encode)
import qualified Data.ByteString.Lazy as BSL
import Data.Text.Encoding (decodeUtf8)

-- | Generate the dispatch instance for the App foundation.
-- This connects the routes defined in config/routes.txt to their handlers.
mkYesodDispatch "App" resourcesApp

-- | Create the complete WAI application by wrapping the foundation
-- with necessary middleware (logging, etc.).
makeApplication :: App -> IO Application
makeApplication foundation = do
    logWare <- makeLogWare foundation
    appPlain <- toWaiAppPlain foundation
    return $ logWare $ appPlain

-- | Initialize the application foundation.
-- This includes loading settings and setting up shared resources like the logger.
makeFoundation :: AppSettings -> IO App
makeFoundation settings = do
    -- Create shared logger set for the application
    loggerSet <- newStdoutLoggerSet defaultBufSize
    
    -- Construct the foundation record
    let foundation = App
            { appSettings = settings
            , appLogger = loggerSet
            }
    
    return foundation

-- | Create the logging middleware based on the application settings.
-- In development, it uses a detailed human-readable format.
-- In production, it uses a structured JSON format for machine consumption.
makeLogWare :: App -> IO Middleware
makeLogWare foundation = do
    let settings = appSettings foundation
    let isDev = appDevelopment settings
    
    if isDev
        then mkRequestLogger def { outputFormat = Detailed True }
        else mkRequestLogger def
            { outputFormat = CustomOutputFormatWithBuilder $ \date req status _len _reqBody _resBody _time ->
                let logEntry = object
                        [ "time" .= decodeUtf8 (BSL.toStrict date)
                        , "method" .= decodeUtf8 (requestMethod req)
                        , "path" .= decodeUtf8 (rawPathInfo req)
                        , "status" .= status
                        , "ip" .= show (remoteHost req)
                        , "user_agent" .= (decodeUtf8 <$> requestHeaderUserAgent req)
                        ]
                in toLogStr (encode logEntry) <> "\n"
            , destination = Logger (appLogger foundation)
            }
