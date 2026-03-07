{-|
Module      : Handler.Health
Description : Health check endpoint handler
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Health check endpoint for monitoring and load balancer probes.
-}

module Handler.Health
    ( getHealthR
    ) where

import Import
import Data.Time.Clock (getCurrentTime)
import Data.Time.Format (formatTime, defaultTimeLocale)
import Control.Monad (when)

-- | Health check endpoint handler
-- Returns basic health status and version information
getHealthR :: Handler Value
getHealthR = do
    -- Add CORS headers
    app <- getYesod
    let cors = appCORS (appSettings app)
    when (corsEnabled cors) $ do
        addHeader "Access-Control-Allow-Origin" "*"
        addHeader "Access-Control-Allow-Methods" "GET, POST, OPTIONS"
        addHeader "Access-Control-Allow-Headers" "Content-Type"
    
    now <- liftIO getCurrentTime
    let timestamp = formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%S%Z" now
    
    return $ object
        [ "status" .= ("healthy" :: Text)
        , "service" .= ("medicus-api" :: Text)
        , "version" .= ("0.1.0" :: Text)
        , "timestamp" .= timestamp
        ]
