module TicTacToe exposing
    ( Cell(..)
    , Model
    , TicTacToeCommon
    , TicTacToeLocal
    , TicTacToeShared
    )

import Array exposing (Array)
import Common exposing (GameId, PlayerId)
import Dict exposing (Dict)


type alias Model =
    { gameId : GameId
    , local : TicTacToeLocal
    , shared : TicTacToeShared
    , common : TicTacToeCommon
    , others : Dict PlayerId TicTacToeShared
    }


type alias TicTacToeLocal =
    {}


type alias TicTacToeShared =
    { isCross : Bool
    }


type alias TicTacToeCommon =
    { grid : Array (Array Cell)
    }


type Cell
    = Cross
    | Naught
    | Empty
