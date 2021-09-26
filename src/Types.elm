module Types exposing
    ( BackendModel
    , BackendMsg(..)
    , Context
    , FrontendModel
    , FrontendMsg(..)
    , ToBackend(..)
    , ToFrontend(..)
    )

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Common exposing (Email, PasswordHash, PlayerId, User)
import Dict exposing (Dict)
import L10N exposing (Language)
import Lamdera exposing (ClientId, SessionId)
import Route exposing (Page, Route(..))
import Time
import Url exposing (Url)
import Url.Parser exposing ((</>))
import UsersDb exposing (UsersDb)


type alias Context =
    { tz : Time.Zone
    , language : Language
    }


type alias FrontendModel =
    { key : Key
    , size : ( Int, Int )
    , context : Context
    , page : Page
    }


type alias BackendModel =
    { users : UsersDb
    , activeSessions : Dict SessionId ActiveSession
    , activeGames : GameDict ()
    }


type alias ActiveSession =
    { session : Session
    , lastSeen : Time.Posix
    }


type Session
    = LoggedInSession PlayerId
    | AnonymousSession { nickname : String }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | Timezone Time.Zone
    | Size ( Int, Int )
    | Login Email PasswordHash
    | Logout
    | UpdatePage Page


type ToBackend
    = TBLogin Email PasswordHash
    | TBLogout
    | TBChangeNickname String


type BackendMsg
    = ClientConnected SessionId ClientId
    | TimedMsg Time.Posix ToBackend


type ToFrontend
    = TFLoginResult (Result String User)
    | TFLogout
