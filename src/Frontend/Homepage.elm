module Frontend.Homepage exposing (view)

import Common exposing (User)
import Element.WithContext as Element exposing (centerX, centerY, column, el, fill, height, px, scrollbarY, width, wrappedRow)
import Element.WithContext.Font as Font
import Element.WithContext.Input as Input
import Frontend.Common exposing (Msg)
import Route exposing (AuthorizedPage(..), GamePage(..), GameRoute(..), Page(..), Route(..))
import Theme exposing (Element)
import TicTacToe
import Types exposing (..)


view : Maybe User -> Element Msg
view maybeUser =
    el [ width fill, height fill ] <|
        wrappedRow
            [ centerX
            , centerY
            , Theme.padding
            , scrollbarY
            ]
            [ ticktactoeSlot maybeUser ]


ticktactoeSlot : Maybe User -> Element Msg
ticktactoeSlot maybeUser =
    let
        next =
            case maybeUser of
                Nothing ->
                    LoginPage <|
                        Route.initLoginPageData <|
                            GameRoute TicTacToeLobbyRoute

                Just user ->
                    AuthorizedPage user <| GamePage <| TicTacToePage TicTacToe.init
    in
    Element.link []
        { label =
            Theme.box [ Font.size 40 ] <|
                column []
                    [ Element.text "Play TicTacToe"
                    , Element.image [ width <| px 100, centerX ]
                        { src = "https://upload.wikimedia.org/wikipedia/commons/f/f6/Tic_Tac_Toe.png"
                        , description = "Example of a TicTacToe match"
                        }
                    ]
        , url = next
        }
