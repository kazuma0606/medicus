{-|
Module      : Handler.Playground
Description : GraphQL Playground handler
Copyright   : (c) MEDICUS Research Team, 2026
License     : BSD-3-Clause

GraphQL Playground UI for interactive API exploration (development only).
-}

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Handler.Playground
    ( getPlaygroundR
    ) where

import Import
import Text.Hamlet (hamletFile)
import qualified Data.Text as T

-- | GraphQL Playground handler (GET)
getPlaygroundR :: Handler Html
getPlaygroundR = do
    app <- getYesod
    let settings = appSettings app
        graphqlSettings = appGraphQL settings
    
    -- Check if playground is enabled
    unless (graphqlPlaygroundEnabled graphqlSettings) $
        permissionDenied "GraphQL Playground is disabled"
    
    -- Serve playground HTML
    defaultLayout $ do
        setTitle "GraphQL Playground - MEDICUS API"
        [whamlet|
            <!DOCTYPE html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <title>GraphQL Playground - MEDICUS API
                    <link rel="stylesheet" href="//cdn.jsdelivr.net/npm/graphql-playground-react/build/static/css/index.css">
                    <link rel="shortcut icon" href="//cdn.jsdelivr.net/npm/graphql-playground-react/build/favicon.png">
                    <script src="//cdn.jsdelivr.net/npm/graphql-playground-react/build/static/js/middleware.js">
                <body>
                    <div id="root">
                    <script>
                        window.addEventListener('load', function (event) {
                            GraphQLPlayground.init(document.getElementById('root'), {
                                endpoint: '#{graphqlEndpoint graphqlSettings}',
                                settings: {
                                    'editor.theme': 'dark',
                                    'request.credentials': 'include'
                                }
                            })
                        })
        |]
