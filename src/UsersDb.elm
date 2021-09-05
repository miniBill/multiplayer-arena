module UsersDb exposing
    ( UsersDb
    , getUserByEmailAndPassowrd
    , getUserByPlayerId
    , init
    , registerUser
    , updateUserByPlayerId
    )

import Common exposing (Email, Nickname, PasswordHash, PlayerId, User)
import Dict exposing (Dict)


type UsersDb
    = UsersDb
        { users : Dict PlayerId ( User, PasswordHash )
        , emailToPlayerId : Dict Email PlayerId
        }


init : UsersDb
init =
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


updateUserByPlayerId : PlayerId -> (User -> User) -> UsersDb -> UsersDb
updateUserByPlayerId playerId f (UsersDb db) =
    UsersDb
        { db
            | users =
                Dict.update playerId
                    (Maybe.map <| Tuple.mapFirst f)
                    db.users
        }
