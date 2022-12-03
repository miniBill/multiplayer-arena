module Types.GameId exposing (Dict, GameId, dict, fromString, toString, urlParser)

import Any.Dict as Dict
import Url.Parser


type GameId
    = GameId String


type alias Dict v =
    Dict.Dict GameId v String


dict : Dict.Interface GameId v v2 output String
dict =
    Dict.makeInterface
        { toComparable = \(GameId i) -> i
        , fromComparable = GameId
        }


urlParser : Url.Parser.Parser (GameId -> a) a
urlParser =
    Url.Parser.map GameId Url.Parser.string


toString : GameId -> String
toString (GameId i) =
    i


fromString : String -> GameId
fromString =
    GameId
