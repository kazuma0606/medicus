{-|
Module      : Settings
Description : Application settings and configuration
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

Application configuration management, including:
- YAML configuration file parsing
- Environment variable overrides
- Development/production settings
-}

{-# LANGUAGE CPP #-}

module Settings
    ( AppSettings(..)
    , GraphQLSettings(..)
    , CORSSettings(..)
    , LoggingSettings(..)
    , RateLimitSettings(..)
    , loadSettings
    , loadSettingsFrom
    ) where

import Data.Aeson
import Data.Aeson.Types (typeMismatch)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Yaml (decodeFileEither)
import System.Environment (lookupEnv)
import Control.Exception (throwIO)

-- | GraphQL-specific settings
data GraphQLSettings = GraphQLSettings
    { graphqlEndpoint :: !Text
    , graphqlPlaygroundEnabled :: !Bool
    , graphqlMaxQueryDepth :: !Int
    } deriving (Show, Eq)

instance FromJSON GraphQLSettings where
    parseJSON = withObject "GraphQLSettings" $ \o -> do
        graphqlEndpoint <- o .: "endpoint"
        graphqlPlaygroundEnabled <- o .:? "playground-enabled" .!= True
        graphqlMaxQueryDepth <- o .:? "max-query-depth" .!= 10
        return GraphQLSettings {..}

-- | CORS settings
data CORSSettings = CORSSettings
    { corsEnabled :: !Bool
    , corsOrigins :: ![Text]
    , corsMethods :: ![Text]
    , corsHeaders :: ![Text]
    } deriving (Show, Eq)

instance FromJSON CORSSettings where
    parseJSON = withObject "CORSSettings" $ \o -> do
        corsEnabled <- o .:? "enabled" .!= True
        corsOrigins <- o .:? "origins" .!= ["*"]
        corsMethods <- o .:? "methods" .!= ["GET", "POST", "OPTIONS"]
        corsHeaders <- o .:? "headers" .!= ["Content-Type"]
        return CORSSettings {..}

-- | Logging settings
data LoggingSettings = LoggingSettings
    { loggingLevel :: !Text
    , loggingFormat :: !Text
    , loggingDestination :: !Text
    } deriving (Show, Eq)

instance FromJSON LoggingSettings where
    parseJSON = withObject "LoggingSettings" $ \o -> do
        loggingLevel <- o .:? "level" .!= "INFO"
        loggingFormat <- o .:? "format" .!= "JSON"
        loggingDestination <- o .:? "destination" .!= "stdout"
        return LoggingSettings {..}

-- | Rate limiting settings
data RateLimitSettings = RateLimitSettings
    { rateLimitEnabled :: !Bool
    , rateLimitRequestsPerMinute :: !Int
    } deriving (Show, Eq)

instance FromJSON RateLimitSettings where
    parseJSON = withObject "RateLimitSettings" $ \o -> do
        rateLimitEnabled <- o .:? "enabled" .!= False
        rateLimitRequestsPerMinute <- o .:? "requests-per-minute" .!= 100
        return RateLimitSettings {..}

-- | Main application settings
data AppSettings = AppSettings
    { appPort :: !Int
    , appHost :: !Text
    , appRoot :: !(Maybe Text)
    , appDevelopment :: !Bool
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

-- | Load settings from the default config file
loadSettings :: IO AppSettings
loadSettings = do
    env <- lookupEnv "YESOD_ENV"
    let configFile = case env of
            Just "production" -> "config/settings-prod.yml"
            _ -> "config/settings.yml"
    loadSettingsFrom configFile

-- | Load settings from a specific file
loadSettingsFrom :: FilePath -> IO AppSettings
loadSettingsFrom path = do
    result <- decodeFileEither path
    case result of
        Left err -> throwIO err
        Right settings -> applyEnvironmentOverrides settings

-- | Apply environment variable overrides
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
