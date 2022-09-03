module Types.PlayerDict exposing (PlayerDict, empty, get, insert, update)

import Common exposing (PlayerId(..))
import Dict exposing (Dict)


type PlayerDict v
    = PlayerDict (Dict String v)


empty : PlayerDict v
empty =
    PlayerDict Dict.empty


insert : PlayerId -> v -> PlayerDict v -> PlayerDict v
insert (PlayerId key) value (PlayerDict dict) =
    PlayerDict (Dict.insert key value dict)


get : PlayerId -> PlayerDict v -> Maybe v
get (PlayerId key) (PlayerDict dict) =
    Dict.get key dict


update : PlayerId -> (Maybe v -> Maybe v) -> PlayerDict v -> PlayerDict v
update (PlayerId key) f (PlayerDict dict) =
    PlayerDict (Dict.update key f dict)
