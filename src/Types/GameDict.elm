module Types.GameDict exposing (GameDict, empty, get, insert, update)

import Common exposing (GameId(..))
import Dict exposing (Dict)


type GameDict v
    = GameDict (Dict String v)


empty : GameDict v
empty =
    GameDict Dict.empty


insert : GameId -> v -> GameDict v -> GameDict v
insert (GameId key) value (GameDict dict) =
    GameDict (Dict.insert key value dict)


get : GameId -> GameDict v -> Maybe v
get (GameId key) (GameDict dict) =
    Dict.get key dict


update : GameId -> (Maybe v -> Maybe v) -> GameDict v -> GameDict v
update (GameId key) f (GameDict dict) =
    GameDict (Dict.update key f dict)
