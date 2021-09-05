module Route exposing
    ( AuthorizedPage(..)
    , GamePage(..)
    , GameRoute(..)
    , LoginPageData
    , Page(..)
    , PublicPage(..)
    , Route(..)
    , initLoginPageData
    , pageToRoute
    , routeToUrl
    , urlToRoute
    )

import Common exposing (GameId, User)
import TicTacToe
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>))


type Page
    = PublicPage (Maybe User) PublicPage
    | LoginPage LoginPageData
    | AuthorizedPage User AuthorizedPage
    | WaitingLoginDataFromServer Route


type PublicPage
    = Homepage
    | FourOhFour


type AuthorizedPage
    = GamePage GamePage


type GamePage
    = TicTacToePage TicTacToe.Model


type Route
    = HomepageRoute
    | FourOhFourRoute
    | LoginRoute
    | GameRoute GameRoute


type GameRoute
    = TicTacToeLobbyRoute
    | TicTacToePlayingRoute GameId


type alias LoginPageData =
    { next : Route
    , email : String
    , password : String
    , error : Maybe String
    }


urlToRoute : Url -> Route
urlToRoute url =
    let
        parser =
            Url.Parser.oneOf
                [ Url.Parser.map HomepageRoute Url.Parser.top
                , Url.Parser.map LoginRoute (Url.Parser.s "login")
                , Url.Parser.map (GameRoute << TicTacToePlayingRoute) (Url.Parser.s "tictactoe" </> Url.Parser.string)
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

                LoginRoute ->
                    [ "login" ]

                GameRoute gameName ->
                    case gameName of
                        TicTacToeLobbyRoute ->
                            [ "tictactoe" ]

                        TicTacToePlayingRoute gameId ->
                            [ "tictactoes", gameId ]
    in
    Url.Builder.absolute path []


pageToRoute : Page -> Route
pageToRoute page =
    case page of
        LoginPage _ ->
            LoginRoute

        WaitingLoginDataFromServer route ->
            route

        PublicPage _ Homepage ->
            HomepageRoute

        PublicPage _ FourOhFour ->
            FourOhFourRoute

        AuthorizedPage _ (GamePage game) ->
            GameRoute <|
                case game of
                    TicTacToePage Nothing ->
                        TicTacToeLobbyRoute

                    TicTacToePage (Just { gameId }) ->
                        TicTacToePlayingRoute gameId


initLoginPageData : Route -> LoginPageData
initLoginPageData next =
    { email =
        let
            _ =
                Debug.todo
        in
        "cmt.miniBill@gmail.com"
    , error = Nothing
    , next = next
    , password =
        let
            _ =
                Debug.todo
        in
        "wololo"
    }
