module Translations exposing (I18n, Language(..), init, joiningGame, languageFromString, languageToString, languages, load)

{-| This file was generated by travelm-agency version 3.0.2.

If you have any issues with the generated code, do not hesitate to open an issue here: <https://github.com/andreasewering/travelm-agency/issues>

-}

import List
import Maybe
import String


{-| Initialize an i18n instance based on a language
-}
init : Language -> I18n
init lang =
    case lang of
        En ->
            en


{-| Switch to another i18n instance based on a language
-}
load : Language -> I18n -> I18n
load lang _ =
    init lang


type alias I18n =
    { joiningGame_ : String -> String }


joiningGame : String -> I18n -> String
joiningGame data i18n =
    i18n.joiningGame_ data


{-| `I18n` instance containing all values for the language En
-}
en : I18n
en =
    { joiningGame_ = \game -> "Joining game " ++ game }


{-| Enumeration of the supported languages
-}
type Language
    = En


{-| A list containing all `Language`s. The list is sorted alphabetically.
-}
languages : List Language
languages =
    [ En ]


{-| Convert a `Language` to its `String` representation.
-}
languageToString : Language -> String
languageToString lang =
    case lang of
        En ->
            "en"


{-| Maybe parse a `Language` from a `String`.
This will map languages based on the prefix i.e. 'en-US' and 'en' will both map to 'En' unless you provided a 'en-US' translation file.
-}
languageFromString : String -> Maybe Language
languageFromString lang =
    let
        helper langs =
            case langs of
                [] ->
                    Maybe.Nothing

                l :: ls ->
                    if String.startsWith (languageToString l) lang then
                        Maybe.Just l

                    else
                        helper ls
    in
    helper (List.reverse languages)
