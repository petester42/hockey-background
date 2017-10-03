{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

import Hockey.Database hiding (port)
import Hockey.Environment
import Hockey.Types (Season(..))
import Hockey.Formatting (formattedGame, formattedSeason, formattedYear, intToInteger, fromStrength, fromEventType, boolToInt)
import Control.Monad.IO.Class
import Yesod
import Data.List as List
import Data.Char as Char

-- Period
instance ToJSON Period where
    toJSON Period {..} = object [ "teamID" .= periodTeamId, "gameID" .= show periodGameId, "period" .= periodPeriod, "goals" .= periodGoals, "shots" .= periodShots ]

-- Seeds
instance ToJSON PlayoffSeed where
    toJSON PlayoffSeed {..} = object [ "seasonID" .= ((formattedYear (intToInteger playoffSeedYear)) ++ (formattedSeason Playoffs)), "conference" .= playoffSeedConference, "seed" .= playoffSeedSeries, "homeID" .= playoffSeedHomeId, "awayID" .= playoffSeedAwayId, "round" .= playoffSeedRound ]

-- Team
instance ToJSON Game where
    toJSON Game {..} = object [ "seasonID" .= ((formattedYear (intToInteger gameYear)) ++ (formattedSeason gameSeason)), "awayID" .= gameAwayId, "homeID" .= gameHomeId, "awayScore" .= gameAwayScore, "homeScore" .= gameHomeScore, "gameID" .= show gameGameId, "date" .= (show gameDate), "time" .= (show gameTime), "tv" .= gameTv, "period" .= gamePeriod, "periodTime" .= List.map Char.toUpper gamePeriodTime, "homeStatus" .= gameHomeStatus, "awayStatus" .= gameAwayStatus, "homeHighlight" .= gameHomeHighlight, "awayHighlight" .= gameAwayHighlight, "homeCondense" .= gameHomeCondense, "awayCondense" .= gameAwayCondense, "active" .= gameActive]

-- Event
instance ToJSON Event where
    toJSON Event {..} = object [ "eventID" .= eventEventId, "gameID" .= show eventGameId, "teamID" .= eventTeamId, "period" .= eventPeriod, "time" .= eventTime, "type" .= (fromEventType eventEventType), "description" .= eventDescription, "videoLink" .= eventVideoLink, "formalID" .= eventFormalId, "strength" .= (fromStrength eventStrength) ]

data PlayoffsResponse = PlayoffsResponse {
    periods :: [Period],
    seeds :: [PlayoffSeed],
    games :: [Game],
    events :: [Event]
} deriving Show

instance ToJSON PlayoffsResponse where
    toJSON PlayoffsResponse {..} = object [ "periods" .= periods, "teams" .= seeds, "games" .= games, "events" .= events ]

data App = App

mkYesod "App" [parseRoutes|
/Hockey/Playoffs PlayoffsR GET
|]

cors :: Yesod site => HandlerT site IO res -> HandlerT site IO res
cors handler = do
    addHeader "Access-Control-Allow-Origin" "*"
    handler
    
instance Yesod App where
    yesodMiddleware = cors . defaultYesodMiddleware 

getPlayoffsR :: Handler Value
getPlayoffsR = liftIO $ do
    e <- env
    p <- selectPeriods (database e) (year e) (season e)
    s <- selectSeeds (database e) (year e)
    g <- selectGamesForSeason (database e) (year e) (season e)
    e <- selectEvents (database e) (year e) (season e)

    returnJson $ PlayoffsResponse p s g e

main :: IO ()
main = do
    e <- env    
    warp (port e) App
