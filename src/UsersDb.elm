module UsersDb exposing
    ( UsersDb
    , getUserByEmailAndPassowrd
    , getUserByPlayerId
    , init
    , registerUser
    , updateUserByPlayerId
    )

import Common exposing (Email, Nickname, PasswordHash, PlayerId(..), User)
import Dict exposing (Dict)
import Types.PlayerDict as PlayerDict exposing (PlayerDict)


type UsersDb
    = UsersDb
        { users : PlayerDict ( User, PasswordHash )
        , emailToPlayerId : Dict Email PlayerId
        }


init : UsersDb
init =
    UsersDb
        { users = PlayerDict.empty
        , emailToPlayerId = Dict.empty
        }


registerUser : Nickname -> Email -> PasswordHash -> UsersDb -> Maybe UsersDb
registerUser nickname email hash (UsersDb { users, emailToPlayerId }) =
    if Dict.member email emailToPlayerId then
        Nothing

    else
        let
            playerId =
                PlayerId email

            newUser =
                { email = email
                , nickname = nickname
                , isAdmin = False
                }
        in
        Just <|
            UsersDb
                { users = PlayerDict.insert playerId ( newUser, hash ) users
                , emailToPlayerId = Dict.insert email playerId emailToPlayerId
                }


getUserByEmailAndPassowrd : Email -> PasswordHash -> UsersDb -> Maybe ( PlayerId, User )
getUserByEmailAndPassowrd email hash (UsersDb { users, emailToPlayerId }) =
    Dict.get email emailToPlayerId
        |> Maybe.andThen
            (\playerId ->
                PlayerDict.get playerId users
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
    PlayerDict.get playerId users
        |> Maybe.map Tuple.first


updateUserByPlayerId : PlayerId -> (User -> User) -> UsersDb -> UsersDb
updateUserByPlayerId playerId f (UsersDb db) =
    UsersDb
        { db
            | users =
                PlayerDict.update playerId
                    (Maybe.map <| Tuple.mapFirst f)
                    db.users
        }
