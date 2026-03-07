{-|
Module      : Application
Description : Application initialization and middleware setup
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Application initialization, including:
- Foundation setup
- Handler registration
- Middleware configuration
- Logging setup
-}

{-# LANGUAGE ViewPatterns #-}

module Application
    ( makeApplication
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
import Network.Wai.Handler.Warp (Settings, defaultSettings, setPort, setHost, HostPreference)
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
    , newFileLoggerSet
    , toLogStr
    , LoggerSet
    , pushLogStrLn
    )
import Network.HTTP.Types (statusCode)
import Network.Wai.Internal (Request(..), Response)
import qualified Data.ByteString as BS
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import Data.Aeson (object, (.=), Value)
import Data.String (fromString)

-- Generate dispatch instance
mkYesodDispatch "App" resourcesApp

-- | Create the Wai application
makeApplication :: App -> IO Application
makeApplication foundation = do
    logWare <- makeLogWare foundation
    appPlain <- toWaiAppPlain foundation
    return $ logWare $ appPlain

-- | Create the foundation with all necessary resources
makeFoundation :: AppSettings -> IO App
makeFoundation settings = do
    -- Create logger
    loggerSet <- newStdoutLoggerSet defaultBufSize
    
    -- Create foundation
    let foundation = App
            { appSettings = settings
            , appLogger = loggerSet
            }
    
    return foundation

-- | Create logging middleware
makeLogWare :: App -> IO Middleware
makeLogWare _foundation = do
    -- Simple logging middleware for now
    mkRequestLogger def
        { outputFormat = Apache FromFallback
        , destination = Callback (\logStr -> putStrLn $ show logStr)
        }

-- | Get Warp settings from app settings
getWarpSettings :: AppSettings -> Settings
getWarpSettings settings =
    setPort (appPort settings)
    $ defaultSettings
