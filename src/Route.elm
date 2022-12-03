module Route exposing
    ( GamePage(..)
    , GameRoute(..)
    , Page(..)
    , Route(..)
    , pageToRoute
    , routeToUrl
    , urlToRoute
    )

import TicTacToe
import Types.GameId as GameId exposing (GameId)
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>))


type Page
    = Homepage
    | FourOhFour
    | GamePage GamePage


type GamePage
    = TicTacToeLobbyPage GameId
    | TicTacToeJoiningPage GameId
    | TicTacToePlayingPage TicTacToe.Model


type Route
    = HomepageRoute
    | FourOhFourRoute
    | GameRoute GameRoute


type GameRoute
    = TicTacToeLobbyRoute
    | TicTacToePlayingRoute GameId


urlToRoute : Url -> Route
urlToRoute url =
    let
        parser =
            Url.Parser.oneOf
                [ Url.Parser.map HomepageRoute Url.Parser.top
                , Url.Parser.map (GameRoute << TicTacToePlayingRoute) (Url.Parser.s "tictactoe" </> GameId.urlParser)
                , Url.Parser.map (GameRoute TicTacToeLobbyRoute) (Url.Parser.s "tictactoe")
                ]
    in
    Url.Parser.parse parser url
        |> Maybe.withDefault FourOhFourRoute


routeToUrl : Route -> String
routeToUrl page =
    let
        path =
            case page of
                HomepageRoute ->
                    []

                FourOhFourRoute ->
                    [ "not-found" ]

                GameRoute gameName ->
                    case gameName of
                        TicTacToeLobbyRoute ->
                            [ "tictactoe" ]

                        TicTacToePlayingRoute gameId ->
                            [ "tictactoes", GameId.toString gameId ]
    in
    Url.Builder.absolute path []


pageToRoute : Page -> Route
pageToRoute page =
    case page of
        Homepage ->
            HomepageRoute

        FourOhFour ->
            FourOhFourRoute

        GamePage game ->
            GameRoute <|
                case game of
                    TicTacToeLobbyPage gameId ->
                        TicTacToePlayingRoute gameId

                    TicTacToeJoiningPage gameId ->
                        TicTacToePlayingRoute gameId

                    TicTacToePlayingPage { gameId } ->
                        TicTacToePlayingRoute gameId
