module Types exposing
    ( AuthorizedPage(..)
    , BackendModel
    , BackendMsg(..)
    , Context
    , FrontendModel
    , FrontendMsg(..)
    , GameModel(..)
    , GameRoute(..)
    , InnerBackendModel
    , Language(..)
    , LoginPageData
    , Page(..)
    , PublicPage(..)
    , Route(..)
    , TBAuthenticated(..)
    , ToBackend(..)
    , ToFrontend(..)
    , initLoginPageData
    , initTicTacToe
    , pageToRoute
    , routeToUrl
    , urlToRoute
    )

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Common exposing (Email, GameId, PasswordHash, PlayerId, User)
import Dict exposing (Dict)
import Lamdera exposing (ClientId, SessionId)
import TicTacToe
import Time
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>))
import UsersDb exposing (UsersDb)


type alias Context =
    { tz : Time.Zone
    , language : Language
    }


type Language
    = English
    | Italian


type alias FrontendModel =
    { key : Key
    , size : ( Int, Int )
    , context : Context
    , page : Page
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


type Page
    = PublicPage (Maybe User) PublicPage
    | LoginPage LoginPageData
    | AuthorizedPage User AuthorizedPage
    | WaitingLoginDataFromServer Route


type PublicPage
    = Homepage
    | FourOhFour


type AuthorizedPage
    = GamePage GameModel


type Route
    = HomepageRoute
    | FourOhFourRoute
    | LoginRoute
    | GameRoute GameRoute


type alias LoginPageData =
    { next : Route
    , email : String
    , password : String
    , error : Maybe String
    }


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


type GameRoute
    = TicTacToeLobbyRoute
    | TicTacToePlayingRoute GameId


type GameModel
    = TicTacToeLobby
    | TicTacToePlaying TicTacToe.Model


type alias BackendModel =
    Maybe InnerBackendModel


type alias InnerBackendModel =
    { users : UsersDb
    , activeSessions : Dict SessionId ActiveSession
    , now : Time.Posix
    }


type alias ActiveSession =
    { playerId : PlayerId
    , lastSeen : Time.Posix
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | Timezone Time.Zone
    | Size ( Int, Int )
    | Login Email PasswordHash
    | Logout
    | UpdatePage Page
    | SwitchPage Page


type ToBackend
    = TBLogin Email PasswordHash
    | TBLogout
    | TBAuthenticated TBAuthenticated


type TBAuthenticated
    = TBChangeNickname String


type BackendMsg
    = ClientConnected SessionId ClientId
    | Tick Time.Posix


type ToFrontend
    = TFLoginResult (Result String User)
    | TFLogout



-- UsersDb


initTicTacToe : GameModel
initTicTacToe =
    TicTacToeLobby


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
                    TicTacToeLobby ->
                        TicTacToeLobbyRoute

                    TicTacToePlaying { gameId } ->
                        TicTacToePlayingRoute gameId
