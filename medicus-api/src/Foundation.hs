{-|
Module      : Foundation
Description : Yesod foundation and routing
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Yesod application foundation, including:
- App type definition
- Routing configuration
- Yesod instance implementation
- Middleware setup
-}

{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE ViewPatterns #-}

module Foundation where

import Yesod.Core
import System.Log.FastLogger (LoggerSet, LogStr, pushLogStrLn, toLogStr, fromLogStr)
import qualified Data.Text as T
import Data.Text (Text)
import Data.Text.Encoding (decodeUtf8)
import Data.Aeson (Value, object, (.=), toJSON)
import qualified Data.Aeson as A
import Numeric.Natural (Natural)
-- import Data.Word (Word64)
import Data.Time.Clock (getCurrentTime)
import Data.Time.Format (formatTime, defaultTimeLocale)
import Settings

-- | The foundation datatype for the application
data App = App
    { appSettings :: AppSettings
    , appLogger :: LoggerSet
    }

-- Define the routes (data types only, dispatch will be in Application module)
-- These are loaded from config/routes.txt
mkYesodData "App" $(parseRoutesFile "config/routes.txt")

-- | Yesod instance
instance Yesod App where
    -- Application root
    approot :: Approot App
    approot = ApprootRequest $ \app req ->
        case appRoot (appSettings app) of
            Nothing -> getApprootText guessApproot app req
            Just root -> root

    -- Default layout (not used for API, but required)
    defaultLayout :: Widget -> Handler Html
    defaultLayout widget = do
        pc <- widgetToPageContent widget
        withUrlRenderer [hamlet|
            $doctype 5
            <html>
                <head>
                    <title>#{pageTitle pc}
                    ^{pageHead pc}
                <body>
                    ^{pageBody pc}
        |]

    -- Error handlers
    errorHandler :: ErrorResponse -> HandlerFor App TypedContent
    errorHandler NotFound = selectRep $ do
        provideRep $ return $ object
            [ "error" .= ("Not Found" :: Text)
            , "status" .= (404 :: Int)
            ]
        provideRep $ return $ toHtml ("Not Found" :: Text)
    
    errorHandler (PermissionDenied msg) = selectRep $ do
        provideRep $ return $ object
            [ "error" .= ("Permission Denied" :: Text)
            , "message" .= msg
            , "status" .= (403 :: Int)
            ]
        provideRep $ return $ toHtml msg
    
    errorHandler (InvalidArgs msgs) = selectRep $ do
        provideRep $ return $ object
            [ "error" .= ("Invalid Arguments" :: Text)
            , "messages" .= msgs
            , "status" .= (400 :: Int)
            ]
        provideRep $ return $ toHtml $ T.intercalate ", " msgs
    
    errorHandler (InternalError msg) = selectRep $ do
        provideRep $ return $ object
            [ "error" .= ("Internal Server Error" :: Text)
            , "message" .= msg
            , "status" .= (500 :: Int)
            ]
        provideRep $ return $ toHtml msg
    
    errorHandler (BadMethod method) = selectRep $ do
        provideRep $ return $ object
            [ "error" .= ("Method Not Allowed" :: Text)
            , "method" .= decodeUtf8 method
            , "status" .= (405 :: Int)
            ]
        provideRep $ return $ toHtml ("Method not allowed: " <> decodeUtf8 method :: Text)

    -- Structured logging
    messageLoggerSource :: App -> LoggerSet -> Loc -> LogSource -> LogLevel -> LogStr -> IO ()
    messageLoggerSource app _loggerSet _loc source level msg = do
        let settings = appSettings app
        if appLoggingFormat (appLogging settings) == "JSON"
            then do
                let logEntry = object
                        [ "source" .= source
                        , "level" .= show level
                        , "message" .= decodeUtf8 (fromLogStr msg)
                        ]
                pushLogStrLn (appLogger app) (toLogStr $ A.encode logEntry)
            else
                pushLogStrLn (appLogger app) $ 
                    "[" <> toLogStr source <> "#" <> toLogStr (show level) <> "] " <> msg

    shouldLogIO :: App -> LogSource -> LogLevel -> IO Bool
    shouldLogIO app _source level = do
        let settings = appSettings app
        let minLevel = case loggingLevel (appLogging settings) of
                "DEBUG" -> LevelDebug
                "INFO" -> LevelInfo
                "WARN" -> LevelWarn
                "ERROR" -> LevelError
                _ -> LevelInfo
        return $ level >= minLevel

-- | Helper for settings access
appLoggingFormat :: LoggingSettings -> Text
appLoggingFormat = loggingFormat

-- | Custom middleware wrapper (CORS headers are added in handlers for now)
-- Future: Implement proper WAI middleware for CORS
