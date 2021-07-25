module Types exposing
    ( AuthorizedPage(..)
    , BackendModel
    , BackendMsg(..)
    , Cell(..)
    , Context
    , Email
    , FrontendModel
    , FrontendMsg(..)
    , GameModel(..)
    , GameRoute(..)
    , InnerBackendModel
    , Language(..)
    , LoginPageData
    , Nickname
    , Page(..)
    , PasswordHash
    , PlayerId
    , PublicPage(..)
    , Route(..)
    , TBAuthenticated(..)
    , TicTacToeCommon
    , TicTacToeLocal
    , TicTacToeShared
    , ToBackend(..)
    , ToFrontend(..)
    , User
    , UsersDb
    , getUserByEmailAndPassowrd
    , getUserByPlayerId
    , initLoginPageData
    , initTicTacToe
    , initUserDb
    , pageToRoute
    , passwordHash
    , registerUser
    , routeToUrl
    , updateUserByPlayerId
    , urlToRoute
    )

import Array exposing (Array)
import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Lamdera exposing (ClientId, SessionId)
import Sha256
import Time
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>))


type alias User =
    { nickname : Nickname
    , isAdmin : Bool
    , email : Email
    }


type alias Nickname =
    String


type alias Email =
    String


type alias PlayerId =
    String


type PasswordHash
    = PasswordHash String


passwordHash : String -> PasswordHash
passwordHash =
    PasswordHash << Sha256.sha256


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


type alias GameId =
    String


type GameModel
    = TicTacToeLobby
    | TicTacToePlaying
        { gameId : GameId
        , local : TicTacToeLocal
        , shared : TicTacToeShared
        , common : TicTacToeCommon
        , others : Dict PlayerId TicTacToeShared
        }


type alias TicTacToeLocal =
    {}


type alias TicTacToeShared =
    { isCross : Bool
    }


type alias TicTacToeCommon =
    { grid : Array (Array Cell)
    }


type Cell
    = Cross
    | Naught
    | Empty


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


type UsersDb
    = UsersDb
        { users : Dict PlayerId ( User, PasswordHash )
        , emailToPlayerId : Dict Email PlayerId
        }


initUserDb : UsersDb
initUserDb =
    UsersDb
        { users = Dict.empty
        , emailToPlayerId = Dict.empty
        }


registerUser : Nickname -> Email -> PasswordHash -> UsersDb -> Maybe UsersDb
registerUser nickname email hash (UsersDb { users, emailToPlayerId }) =
    if Dict.member email emailToPlayerId then
        Nothing

    else
        let
            playerId =
                email

            newUser =
                { email = email
                , nickname = nickname
                , isAdmin = False
                }
        in
        Just <|
            UsersDb
                { users = Dict.insert playerId ( newUser, hash ) users
                , emailToPlayerId = Dict.insert email playerId emailToPlayerId
                }


getUserByEmailAndPassowrd : Email -> PasswordHash -> UsersDb -> Maybe ( PlayerId, User )
getUserByEmailAndPassowrd email hash (UsersDb { users, emailToPlayerId }) =
    Dict.get email emailToPlayerId
        |> Maybe.andThen
            (\playerId ->
                Dict.get playerId users
                    |> Maybe.andThen
                        (\( user, expectedHash ) ->
                            if expectedHash == hash then
                                Just ( playerId, user )

                            else
                                Nothing
                        )
            )


getUserByPlayerId : PlayerId -> UsersDb -> Maybe User
getUserByPlayerId playerId (UsersDb { users }) =
    Dict.get playerId users
        |> Maybe.map Tuple.first


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


updateUserByPlayerId : PlayerId -> (User -> User) -> UsersDb -> UsersDb
updateUserByPlayerId playerId f (UsersDb db) =
    UsersDb
        { db
            | users =
                Dict.update playerId
                    (Maybe.map <| Tuple.mapFirst f)
                    db.users
        }
