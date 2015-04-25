{-# LANGUAGE EmptyDataDecls #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE RecordWildCards #-}

module Hockey.Database.Types (
    migrate,
    Game(..),
    Event(..),
    Team(..),
    PlayoffSeed(..),
    Period(..),
    selectTimeForGame,
    selectGames,
    selectPeriods,
    selectSeeds,
    selectGamesForSeason,
    selectEvents
)

where

import Database.Persist.Postgresql hiding (migrate)
import Database.Persist.Sqlite hiding (migrate)
import Database.Persist.TH
import Hockey.Database.Internal
import Hockey.Types (GameState(..), EventType(..), Strength(..), Season(..), Year(..), AMPM(..))
import Hockey.Formatting (integerToInt, timeFromComponents)
import Data.Time.Calendar
import Data.Time.LocalTime
import Control.Monad.IO.Class
import Control.Monad.Trans.Control
import Data.List as List
import Data.Aeson

-- add Maybe monad to some type
-- have videos be a map
share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
Game
    year Int
    season Season
    gameId Int
    awayId String
    homeId String
    date Day
    time TimeOfDay
    tv String
    state GameState
    period Int
    periodTime String
    awayScore Int
    homeScore Int
    awaySog Int
    homeSog Int
    awayStatus String default=''
    homeStatus String default=''
    awayHighlight String default=''
    homeHighlight String default=''
    awayCondense String default=''
    homeCondense String default=''
    active Bool default=true
    UniqueGameId gameId
    deriving Show
Period
    year Int
    season Season
    gameId Int
    teamId String
    period Int
    shots Int
    goals Int
    UniquePeriodId gameId teamId period
    deriving Show
Event
    eventId Int
    year Int
    season Season
    gameId Int
    teamId String
    period Int
    time String
    eventType EventType
    description String
    videoLink String
    formalId String
    strength Strength
    UniqueEventId eventId gameId
    deriving Show
Team
    teamId String
    city String
    name String
    UniqueTeamId teamId
    deriving Show
PlayoffSeed
    year Int
    season Season
    conference String
    round Int
    seed Int
    homeId String
    awayId String
    UniquePlayoffSeedId year conference round seed
    deriving Show
|]

migrate :: (MonadBaseControl IO m, MonadIO m) => Database -> m ()
migrate database = database `process` (runMigration migrateAll)

selectTimeForGame :: (MonadBaseControl IO m, MonadIO m) => Database -> Int -> m TimeOfDay
selectTimeForGame database gameId = do
    games <- database `process` (selectList [GameGameId ==. gameId] [LimitTo 1])
    case games of
        [] -> return $ timeFromComponents 0 0 AM
        (x:xs) -> return $ (gameTime (entityVal x))

selectGames :: (MonadBaseControl IO m, MonadIO m) => Database -> [Day] -> m [Game]
selectGames database dates = do
    games <- database `process` (selectList [GameDate <-. dates] [])
    return $ List.map entityVal games

selectPeriods :: (MonadBaseControl IO m, MonadIO m) => Database -> Year -> Season -> m [Period]
selectPeriods database year season =  do
    periods <- database `process` (selectList [PeriodYear ==. (integerToInt (fst year)), PeriodSeason ==. season] [])
    return $ List.map entityVal periods

selectSeeds :: (MonadBaseControl IO m, MonadIO m) => Database -> Year -> Season -> m [PlayoffSeed]
selectSeeds database year season =  do
    seeds <- database `process` (selectList [PlayoffSeedYear ==. (integerToInt (fst year)), PlayoffSeedSeason ==. season] [])
    return $ List.map entityVal seeds

selectGamesForSeason :: (MonadBaseControl IO m, MonadIO m) => Database -> Year -> Season -> m [Game]
selectGamesForSeason database year season =  do
    games <- database `process` (selectList [GameYear ==. (integerToInt (fst year)), GameSeason ==. season] [])
    return $ List.map entityVal games

selectEvents :: (MonadBaseControl IO m, MonadIO m) => Database -> Year -> Season -> m [Event]
selectEvents database year season =  do
    events <- database `process` (selectList [EventYear ==. (integerToInt (fst year)), EventSeason ==. season] [])
    return $ List.map entityVal events
