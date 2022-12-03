module Theme exposing (Attribute, Element, box, colors, column, fontSizes, link, padding, row, spacing, text)

import Element.WithContext as Element exposing (Color, el)
import Element.WithContext.Border as Border
import Element.WithContext.Font as Font
import Route exposing (Route)
import Translations exposing (I18n)
import Types exposing (Context)


type alias Element msg =
    Element.Element Context msg


type alias Attribute msg =
    Element.Attribute Context msg


spacing : Attribute msg
spacing =
    Element.spacing rythm


padding : Attribute msg
padding =
    Element.padding rythm


rythm : number
rythm =
    10


colors :
    { errorBackground : Color
    , errorForeground : Color
    }
colors =
    { errorBackground = Element.rgb 1 0.8 0.8
    , errorForeground = Element.rgb 1 0 0
    }


fontSizes :
    { huge : Int
    , bigger : Int
    , big : Int
    , normal : Int
    , small : Int
    , smaller : Int
    , tiny : Int
    }
fontSizes =
    let
        scaled =
            round << Element.modular 16 1.25
    in
    { huge = scaled 4
    , bigger = scaled 3
    , big = scaled 2
    , normal = scaled 1
    , small = scaled -1
    , smaller = scaled -2
    , tiny = scaled -3
    }


box : List (Attribute msg) -> Element msg -> Element msg
box attrs element =
    el
        ([ Border.width 1
         , Border.rounded rythm
         , padding
         ]
            ++ attrs
        )
        element


column : List (Attribute msg) -> List (Element msg) -> Element msg
column attrs =
    Element.column (spacing :: attrs)


row : List (Attribute msg) -> List (Element msg) -> Element msg
row attrs =
    Element.row (spacing :: attrs)


link : List (Attribute msg) -> { label : Element msg, route : Route } -> Element msg
link attrs config =
    Element.link (Font.underline :: attrs)
        { label = config.label
        , url = Route.routeToUrl config.route
        }


text : (I18n -> String) -> Element msg
text content =
    Element.with .i18n (\i18n -> Element.text <| content i18n)
