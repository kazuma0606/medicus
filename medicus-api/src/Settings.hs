{-|
Module      : Settings
Description : Application settings and configuration
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

This module defines the configuration structures for the MEDICUS API
and provides functions to load them from YAML files and environment variables.
-}

{-# LANGUAGE CPP #-}

module Settings
    ( -- * Configuration Records
      AppSettings(..)
    , GraphQLSettings(..)
    , CORSSettings(..)
    , LoggingSettings(..)
    , RateLimitSettings(..)
    
      -- * Loading Functions
    , loadSettings
    , loadSettingsFrom
    ) where

import Data.Aeson
import Data.Text (Text)
import qualified Data.Text as T
import Data.Yaml (decodeFileEither)
import System.Environment (lookupEnv)
import Control.Exception (throwIO)

-- | Settings specifically for the GraphQL engine and playground.
data GraphQLSettings = GraphQLSettings
    { graphqlEndpoint :: !Text
    -- ^ Path where the GraphQL API is served (e.g., "/graphql")
    , graphqlPlaygroundEnabled :: !Bool
    -- ^ Whether to enable the interactive GraphQL Playground
    , graphqlMaxQueryDepth :: !Int
    -- ^ Security: maximum depth allowed for GraphQL queries
    } deriving (Show, Eq)

instance FromJSON GraphQLSettings where
    parseJSON = withObject "GraphQLSettings" $ \o -> do
        graphqlEndpoint <- o .: "endpoint"
        graphqlPlaygroundEnabled <- o .:? "playground-enabled" .!= True
        graphqlMaxQueryDepth <- o .:? "max-query-depth" .!= 10
        return GraphQLSettings {..}

-- | Settings for Cross-Origin Resource Sharing (CORS).
data CORSSettings = CORSSettings
    { corsEnabled :: !Bool
    -- ^ Whether CORS middleware is active
    , corsOrigins :: ![Text]
    -- ^ List of allowed origins (e.g., ["http://localhost:8080"])
    , corsMethods :: ![Text]
    -- ^ Allowed HTTP methods
    , corsHeaders :: ![Text]
    -- ^ Allowed request headers
    } deriving (Show, Eq)

instance FromJSON CORSSettings where
    parseJSON = withObject "CORSSettings" $ \o -> do
        corsEnabled <- o .:? "enabled" .!= True
        corsOrigins <- o .:? "origins" .!= ["*"]
        corsMethods <- o .:? "methods" .!= ["GET", "POST", "OPTIONS"]
        corsHeaders <- o .:? "headers" .!= ["Content-Type"]
        return CORSSettings {..}

-- | Settings for the logging system.
data LoggingSettings = LoggingSettings
    { loggingLevel :: !Text
    -- ^ Minimum log level (DEBUG, INFO, WARN, ERROR)
    , loggingFormat :: !Text
    -- ^ Output format (JSON, Apache)
    , loggingDestination :: !Text
    -- ^ Where to write logs (stdout, file path)
    } deriving (Show, Eq)

instance FromJSON LoggingSettings where
    parseJSON = withObject "LoggingSettings" $ \o -> do
        loggingLevel <- o .:? "level" .!= "INFO"
        loggingFormat <- o .:? "format" .!= "JSON"
        loggingDestination <- o .:? "destination" .!= "stdout"
        return LoggingSettings {..}

-- | Settings for the API rate limiter.
data RateLimitSettings = RateLimitSettings
    { rateLimitEnabled :: !Bool
    -- ^ Whether to restrict requests per time period
    , rateLimitRequestsPerMinute :: !Int
    -- ^ Quota allowed per minute per client
    } deriving (Show, Eq)

instance FromJSON RateLimitSettings where
    parseJSON = withObject "RateLimitSettings" $ \o -> do
        rateLimitEnabled <- o .:? "enabled" .!= False
        rateLimitRequestsPerMinute <- o .:? "requests-per-minute" .!= 100
        return RateLimitSettings {..}

-- | Root configuration object for the entire application.
data AppSettings = AppSettings
    { appPort :: !Int
    -- ^ Port number Warp should listen on
    , appHost :: !Text
    -- ^ Host/Interface Warp should bind to
    , appRoot :: !(Maybe Text)
    -- ^ Optional base URL for generating absolute links
    , appDevelopment :: !Bool
    -- ^ Whether the app is running in development mode (extra logging, etc.)
    , appGraphQL :: !GraphQLSettings
    , appCORS :: !CORSSettings
    , appLogging :: !LoggingSettings
    , appRateLimit :: !RateLimitSettings
    } deriving (Show, Eq)

instance FromJSON AppSettings where
    parseJSON = withObject "AppSettings" $ \o -> do
        appPort <- o .:? "port" .!= 3000
        appHost <- o .:? "host" .!= "localhost"
        appRoot <- o .:? "approot"
        appDevelopment <- o .:? "development" .!= False
        appGraphQL <- o .:? "graphql" .!= GraphQLSettings
            { graphqlEndpoint = "/graphql"
            , graphqlPlaygroundEnabled = True
            , graphqlMaxQueryDepth = 10
            }
        appCORS <- o .:? "cors" .!= CORSSettings
            { corsEnabled = True
            , corsOrigins = ["*"]
            , corsMethods = ["GET", "POST", "OPTIONS"]
            , corsHeaders = ["Content-Type"]
            }
        appLogging <- o .:? "logging" .!= LoggingSettings
            { loggingLevel = "INFO"
            , loggingFormat = "JSON"
            , loggingDestination = "stdout"
            }
        appRateLimit <- o .:? "rate-limit" .!= RateLimitSettings
            { rateLimitEnabled = False
            , rateLimitRequestsPerMinute = 100
            }
        return AppSettings {..}

-- | Load settings from the default configuration files.
-- It checks the 'YESOD_ENV' environment variable to decide between
-- production and development settings.
loadSettings :: IO AppSettings
loadSettings = do
    env <- lookupEnv "YESOD_ENV"
    let configFile = case env of
            Just "production" -> "config/settings-prod.yml"
            _ -> "config/settings.yml"
    loadSettingsFrom configFile

-- | Load settings from a specific YAML file.
loadSettingsFrom :: FilePath -> IO AppSettings
loadSettingsFrom path = do
    result <- decodeFileEither path
    case result of
        Left err -> throwIO err
        Right settings -> applyEnvironmentOverrides settings

-- | Internal helper to override loaded YAML settings with environment variables.
applyEnvironmentOverrides :: AppSettings -> IO AppSettings
applyEnvironmentOverrides settings = do
    port <- lookupEnv "PORT"
    host <- lookupEnv "HOST"
    approot <- lookupEnv "APPROOT"
    
    let settings' = settings
            { appPort = maybe (appPort settings) read port
            , appHost = maybe (appHost settings) T.pack host
            , appRoot = case approot of
                Nothing -> appRoot settings
                Just r -> Just (T.pack r)
            }
    
    return settings'
