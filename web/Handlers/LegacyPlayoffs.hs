module Handlers.LegacyPlayoffs
  ( getLegacyPlayoffsR
  ) where

import Hockey.Database
import Hockey.Environment
import Hockey.Types (Season(..))
import Models.LegacyJson
import Yesod

getLegacyPlayoffsR :: HandlerFor site Value
getLegacyPlayoffsR =
  liftIO $ do
    e <- env
    p <- selectPeriods (database e) (year e) Playoffs
    s <- selectSeeds (database e) (year e)
    g <- selectGamesForSeason (database e) (year e) Playoffs
    e <- selectEvents (database e) (year e) Playoffs
    returnJson $ PlayoffsResponse p s g e
