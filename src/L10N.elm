module L10N exposing (L10N, Language(..), l6e, map)


type Language
    = English
    | Italian


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
