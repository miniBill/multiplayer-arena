module TicTacToe exposing
    ( Common
    , Local
    , Model
    , Shared
    , initCommon
    , initLocal
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Types.Common exposing (PublicProfile)
import Types.GameId as GameId exposing (GameId)
import Types.PlayerId as PlayerId exposing (PlayerId)


type alias Model =
    { gameId : GameId
    , local : Local
    , shared : Shared
    , common : Common
    , others :
        PlayerId.Dict
            { profile : PublicProfile
            , shared : Shared
            }
    }


{-| Player-owned state, never shared.
-}
type alias Local =
    {}


{-| Player-owned state, shared with other players
-}
type alias Shared =
    {}


{-| Server-owned state.
-}
type alias Common =
    { crossPlayer : PlayerId
    , naughtPlayer : PlayerId
    , grid : Array (Array Cell)
    }


type Player
    = Naught
    | Cross


type alias Cell =
    Maybe Player


initLocal : {}
initLocal =
    {}


initCommon :
    { crossPlayer : PlayerId
    , naughtPlayer : PlayerId
    }
    -> Common
initCommon { crossPlayer, naughtPlayer } =
    { crossPlayer = crossPlayer
    , naughtPlayer = naughtPlayer
    , grid = Array.repeat 3 (Array.repeat 3 Nothing)
    }
