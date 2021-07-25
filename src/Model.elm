module Model exposing (L10N, l6e, map)

import Types exposing (Language(..))


type alias L10N a =
    { en : a, it : a }


map : (a -> b) -> L10N a -> L10N b
map f { en, it } =
    { en = f en
    , it = f it
    }


l6e : L10N a -> Language -> a
l6e { en, it } lang =
    case lang of
        English ->
            en

        Italian ->
            it
