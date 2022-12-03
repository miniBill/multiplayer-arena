module Frontend.Homepage exposing (view)

import Element.WithContext as Element exposing (centerX, centerY, column, el, fill, height, px, scrollbarY, width, wrappedRow)
import Element.WithContext.Font as Font
import Route exposing (GamePage(..), GameRoute(..), Page(..), Route(..))
import Theme exposing (Element)
import Types exposing (FrontendMsg)


view : Element FrontendMsg
view =
    el [ width fill, height fill ] <|
        wrappedRow
            [ centerX
            , centerY
            , Theme.padding
            , scrollbarY
            ]
            [ ticktactoeSlot ]


ticktactoeSlot : Element FrontendMsg
ticktactoeSlot =
    Theme.link []
        { label =
            Theme.box [ Font.size 40 ] <|
                column []
                    [ Element.text "Play TicTacToe"
                    , Element.image [ width <| px 100, centerX ]
                        { src = "https://upload.wikimedia.org/wikipedia/commons/f/f6/Tic_Tac_Toe.png"
                        , description = "Example of a TicTacToe match"
                        }
                    ]
        , route = GameRoute TicTacToeLobbyRoute
        }
