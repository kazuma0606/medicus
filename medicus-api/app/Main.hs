{-|
Module      : Main
Description : Application entry point
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Main entry point for the MEDICUS API server.
-}

module Main where

import Application (makeApplication, makeFoundation)
import Settings
import Network.Wai.Handler.Warp
    ( run
    , runSettings
    , setPort
    , setHost
    , setOnException
    , defaultSettings
    , HostPreference
    )
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import qualified Data.ByteString.Char8 as BS
import Control.Exception (bracket, SomeException)
import System.IO (hSetBuffering, stdout, stderr, BufferMode(LineBuffering))

-- | Main entry point
main :: IO ()
main = do
    -- Set line buffering for stdout
    hSetBuffering stdout LineBuffering
    
    -- Load settings
    settings <- loadSettings
    
    -- Print startup message
    TIO.putStrLn "==================================="
    TIO.putStrLn "  MEDICUS API Server Starting..."
    TIO.putStrLn "==================================="
    TIO.putStrLn $ "Port: " <> T.pack (show (appPort settings))
    TIO.putStrLn $ "Host: " <> appHost settings
    TIO.putStrLn $ "Environment: " <> if appDevelopment settings then "Development" else "Production"
    TIO.putStrLn $ "GraphQL Endpoint: " <> graphqlEndpoint (appGraphQL settings)
    TIO.putStrLn $ "GraphQL Playground: " <> if graphqlPlaygroundEnabled (appGraphQL settings) then "Enabled" else "Disabled"
    TIO.putStrLn "==================================="
    
    -- Create foundation and run application
    bracket
        (makeFoundation settings)
        (\_ -> TIO.putStrLn "\nShutting down...")
        $ \foundation -> do
            app <- makeApplication foundation
            let warpSettings = setPort (appPort settings)
                             $ setHost (textToHostPreference $ appHost settings)
                             $ defaultSettings
            
            TIO.putStrLn $ "Server running on http://" <> appHost settings <> ":" <> T.pack (show (appPort settings))
            TIO.putStrLn "Press Ctrl+C to stop"
            TIO.putStrLn ""
            
            runSettings warpSettings app

-- | Convert Text to HostPreference
textToHostPreference :: T.Text -> HostPreference
textToHostPreference "*" = "*"
textToHostPreference "*4" = "*4"
textToHostPreference "*6" = "*6"
textToHostPreference t = fromString (T.unpack t)
