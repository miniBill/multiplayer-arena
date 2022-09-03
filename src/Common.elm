module Common exposing
    ( Email
    , GameId(..)
    , Nickname
    , PasswordHash
    , PlayerId(..)
    , User
    , passwordHash
    )

import Sha256


type alias Nickname =
    String


type alias Email =
    String


type alias User =
    { nickname : Nickname
    , isAdmin : Bool
    , email : Email
    }


type PlayerId
    = PlayerId String


type GameId
    = GameId String


type PasswordHash
    = PasswordHash String


passwordHash : String -> PasswordHash
passwordHash =
    PasswordHash << Sha256.sha256
