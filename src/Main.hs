{-# LANGUAGE OverloadedStrings #-}
module Main where

import Prelude hiding (log)
import Network.HTTP.Client.TLS  (tlsManagerSettings)
import Web.Telegram.API.Bot
import Control.Monad.IO.Class
import Control.Concurrent
import Database
import Actions
import Data.Maybe
import Logger
import Data.String
import System.Log.FastLogger
import Network.HTTP.Client
import Data.Text (pack)
import Control.Monad.Reader (ask)
import System.Environment
import Control.Monad



main :: IO ()
main = do
    {-args <- getArgs -}
    {-forM_ args $ \x -> do-}
        {-convertToJSON (read x) "los-programadores-all/"-}
    token <- Token . pack <$> getEnv "TOKEN"
    print token
    logger <- startLogger
    manager <- newManager tlsManagerSettings
    migrate
    exit <- runClient (client logger manager) token manager
    print exit
    return ()

client :: LoggerSet -> Manager -> TelegramClient ()
client logger manager = forever $ do
    lastOffset <- liftIO . runDB $ getLastOffset
    log logger (fromString . show $ lastOffset)
    token <- ask
    updates <- liftIO $ getUpdates token lastOffset Nothing Nothing  manager
    case updates of
        Left err -> log logger (fromString $ show err)
        Right us -> do
            newUpdates <- fmap catMaybes . liftIO $ runDB (mapM saveUpdateMessage (result us))
            mapM_ (processAction logger) newUpdates
    liftIO $ threadDelay 3000000
