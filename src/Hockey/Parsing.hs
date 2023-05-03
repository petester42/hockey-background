{-# LANGUAGE OverloadedStrings #-}

module Hockey.Parsing (
    decodeResponse
) where

import Hockey.Formatting
import Data.Aeson
import Control.Applicative as Applicative
import Hockey.Types
import Data.Text

decodeResponse :: (FromJSON a) => IO String -> IO (Maybe a)
decodeResponse response = do
    rsp <- response
    return $ decode (stringToLazyByteString rsp)

-- Season
instance FromJSON Season

-- GameState
instance FromJSON GameState

-- TeamData
instance FromJSON TeamData where
    parseJSON (Object v) = TeamData <$>
        fmap unpackToLower (v .: "abbreviation")
    parseJSON _          = Applicative.empty

-- TeamInfo
instance FromJSON TeamInfo where
    parseJSON (Object v) = TeamInfo <$>
        (v .: "team")
    parseJSON _          = Applicative.empty

-- Teams
instance FromJSON Teams where
    parseJSON (Object v) = Teams <$>
      (v .: "away") <*>
      (v .: "home")
    parseJSON _          = Applicative.empty

-- Broadcast
instance FromJSON Broadcast where
    parseJSON (Object v) = Broadcast <$>
        (v .: "name")
    parseJSON _          = Applicative.empty

-- PeriodData
instance FromJSON PeriodData where
    parseJSON (Object v) = PeriodData <$>
        (v .: "goals") <*>
        (v .: "shotsOnGoal")
    parseJSON _          = Applicative.empty

-- Period
instance FromJSON Period where
    parseJSON (Object v) = Period <$>
        (v .: "num") <*>
        (v .: "home") <*>
        (v .: "away")
    parseJSON _          = Applicative.empty

-- ScoreInfo
instance FromJSON ScoreInfo where
    parseJSON (Object v) = ScoreInfo <$>
        (v .: "goals") <*>
        (v .: "shotsOnGoal") <*>
        (v .: "powerPlay") <*>
        (v .: "goaliePulled")
    parseJSON _          = Applicative.empty

-- ScoreTeams
instance FromJSON ScoreTeams where
    parseJSON (Object v) = ScoreTeams <$>
        (v .: "home") <*>
        (v .: "away")
    parseJSON _          = Applicative.empty

-- Linescore
instance FromJSON Linescore where
    parseJSON (Object v) = Linescore <$>
        (v .: "periods") <*>
        (v .: "currentPeriod") <*>
        (v .:? "currentPeriodTimeRemaining" .!= "20:00") <*>
        (v .: "teams")
    parseJSON _          = Applicative.empty

-- State
instance FromJSON State where
    parseJSON (Object v) = State <$>
        fmap (toGameState . valueToInteger) (v .: "statusCode")
    parseJSON _          = Applicative.empty

-- GameDateTime
instance FromJSON GameDateTime where
    parseJSON (String v) = return $ convertToEST (unpackParseDateTime' $ unpack v)
    parseJSON _          = Applicative.empty

-- VideoLink
instance FromJSON VideoLink where
    parseJSON (Object v) = VideoLink <$>
        fmap toVideoQuality (v .: "name") <*>
        (v .: "url")
    parseJSON _ = Applicative.empty

-- LinkType
instance FromJSON LinkType where
    parseJSON (Object v) = LinkType <$>
        (v .:? "playbacks" .!= [])
    parseJSON _          = Applicative.empty

-- MediaItem
instance FromJSON MediaItem where
    parseJSON (Object v) = MediaItem <$>
        fmap toVideoType (v .: "title") <*>
        (v .: "items")
    parseJSON _          = Applicative.empty

-- Media
instance FromJSON Media where
    parseJSON (Object v) = Media <$>
        (v .: "epg")
    parseJSON _          = Applicative.empty

-- Content
instance FromJSON Content where
    parseJSON (Object v) = Content <$>
        (v .:? "media")
    parseJSON _          = Applicative.empty


emptyScoreInfo :: ScoreInfo
emptyScoreInfo = ScoreInfo 0 0 False False

emptyScoreTeams :: ScoreTeams
emptyScoreTeams = ScoreTeams emptyScoreInfo emptyScoreInfo

emptyLineScore:: Linescore 
emptyLineScore = Linescore [] 0 "20:00" emptyScoreTeams

-- Game
instance FromJSON Game where
    parseJSON (Object v) = Game <$>
        (v .: "gameDate") <*>
        fmap seasonFromGameId (v .: "gamePk") <*>
        (v .: "gamePk") <*>
        (v .: "teams") <*>
        (v .:? "broadcasts" .!= []) <*>
        (v .:? "linescore" .!= emptyLineScore) <*>
        (v .: "status") <*>
        (v .: "content")
    parseJSON _          = Applicative.empty

-- Results
instance FromJSON Results where
    parseJSON (Object v) = Results <$>
        (v .: "dates")
    parseJSON _          = Applicative.empty

-- GameDates
instance FromJSON GameDates where
    parseJSON (Object v) = GameDates <$>
        (v .: "games")
    parseJSON _          = Applicative.empty

-- EventType
instance FromJSON EventType

-- Strength
instance FromJSON Strength

-- Event
instance FromJSON Event where
    parseJSON (Object v) = parseEvent v
    parseJSON _          = Applicative.empty

parseEvent v = Event <$>
    v .: "eventid" <*>
    v .: "teamid" <*>
    v .: "period" <*>
    v .: "time" <*>
    v .: "desc" <*>
    v .: "formalEventId" <*>
    fmap toStrength (v .: "strength") <*>
    v .: "type"

-- EventPlays
instance FromJSON EventPlays where
    parseJSON (Object v) = parseEventPlays v
    parseJSON _          = Applicative.empty

parseEventPlays v = EventPlays <$>
        v .: "play"

-- EventGame
instance FromJSON EventGame where
    parseJSON (Object v) = parseEventGame v
    parseJSON _          = Applicative.empty

parseEventGame v = EventGame <$>
    v .: "awayteamid" <*>
    v .: "hometeamid" <*>
    v .: "awayteamnick" <*>
    v .: "hometeamnick" <*>
    v .: "plays"

-- EventData
instance FromJSON EventData where
    parseJSON (Object v) = parseEventData v
    parseJSON _          = Applicative.empty

parseEventData v = EventData <$>
    v .: "game"

-- GameEvents
instance FromJSON GameEvents where
    parseJSON (Object v) = parseGameEvents v
    parseJSON _          = Applicative.empty

parseGameEvents v = GameEvents <$>
    v .: "data"

instance FromJSON ScoreboardData where
    parseJSON (Object v) = parseScoreboardData v
    parseJSON _          = Applicative.empty

parseScoreboardData v = ScoreboardData <$>
        fmap unpackToLower (v .: "ab") <*>
        v .: "pa"

instance FromJSON Scoreboard where
    parseJSON (Object v) = parseScoreboard v
    parseJSON _          = Applicative.empty

parseScoreboard v = Scoreboard <$>
    v .: "h" <*>
    v .: "a"
