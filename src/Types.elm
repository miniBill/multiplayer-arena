module Types exposing
    ( BackendModel
    , BackendMsg(..)
    , Context
    , FrontendModel
    , FrontendMsg(..)
    , Session
    , ToBackend(..)
    , ToFrontend(..)
    )

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Lamdera exposing (ClientId, SessionId)
import Route exposing (Page)
import TicTacToe
import Time
import Translations exposing (I18n)
import Types.GameId as GameId
import Types.PlayerId as PlayerId
import Url exposing (Url)


type alias Context =
    { tz : Time.Zone
    , i18n : I18n
    }


type alias FrontendModel =
    { key : Key
    , size : ( Int, Int )
    , context : Context
    , page : Page
    }


type alias BackendModel =
    { sessions : Dict SessionId Session
    , games : GameId.Dict Game
    }


type Game
    = TicTacToeGame
        { shared : PlayerId.Dict TicTacToe.Shared
        , common : TicTacToe.Common
        }


type alias Session =
    { nickname : String
    , lastSeen : Time.Posix
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | Timezone Time.Zone
    | Size ( Int, Int )
    | UpdatePage Page


type ToBackend
    = TBChangeNickname String


type BackendMsg
    = ClientConnected SessionId ClientId
    | TimedMsg Time.Posix ToBackend


type ToFrontend
    = TFNop
