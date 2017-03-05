{-# LANGUAGE OverloadedStrings #-}
module Main where

import Prelude hiding (log)
import Network.HTTP.Client (newManager)
import Network.HTTP.Client.TLS  (tlsManagerSettings)
import Web.Telegram.API.Bot
import Control.Monad.IO.Class
import Control.Monad
import Control.Concurrent
import Database
import Actions
import Data.Maybe
import Logger
import Data.String
import System.Log.FastLogger
import Tests
import Network.HTTP.Client


token :: Token
token = Token "bot312434737:AAF0tWwVauiLE637wgyOjXntiPO0HRAPRNs"



main :: IO ()
main = do
    logger <- startLogger
    manager <- newManager tlsManagerSettings
    migrate
    runClient (client logger manager) token manager
    return ()

client :: LoggerSet -> Manager -> TelegramClient ()
client logger manager = forever $ do
    lastOffset <- liftIO . runDB $ getLastOffset
    log logger $ (fromString . show $ lastOffset)
    updates <- liftIO $ getUpdates token lastOffset Nothing Nothing  manager
    case updates of
        Left err -> log logger (fromString $ show err)
        Right us -> do
            newUpdates <- liftM catMaybes . liftIO $ runDB (mapM saveUpdateMessage (result us))
            mapM_ (processAction logger) newUpdates
    liftIO $ threadDelay 3000000
