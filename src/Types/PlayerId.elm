module Types.PlayerId exposing (Dict, PlayerId, dict)

import Any.Dict as Dict


type PlayerId
    = PlayerId String


type alias Dict v =
    Dict.Dict PlayerId v String


dict : Dict.Interface PlayerId v v2 output String
dict =
    Dict.makeInterface
        { toComparable = \(PlayerId i) -> i
        , fromComparable = PlayerId
        }
