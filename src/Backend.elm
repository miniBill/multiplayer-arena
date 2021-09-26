module Backend exposing (..)

import Common as Common exposing (PasswordHash, PlayerId, User)
import Dict
import Lamdera exposing (ClientId, SessionId)
import Process
import Task
import Time
import Types exposing (..)
import Update.Pipeline as Update
import UsersDb as UsersDb


type alias Model =
    BackendModel


type alias Msg =
    BackendMsg


type alias InnerModel =
    InnerBackendModel


app :
    { init : ( Model, Cmd Msg )
    , update : Msg -> Model -> ( Model, Cmd Msg )
    , updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd Msg )
    , subscriptions : Model -> Sub Msg
    }
app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Lamdera.onConnect ClientConnected


init : ( Model, Cmd Msg )
init =
    Update.save Nothing


superAdmin : ( User, PasswordHash )
superAdmin =
    ( superAdminUser, Common.passwordHash "wololo" )


superAdminUser : User
superAdminUser =
    { email = "cmt.miniBill@gmail.com"
    , isAdmin = True
    , nickname = "miniBill"
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg m =
    case ( m, msg ) of
        ( Just model, Tick now ) ->
            Update.save <| Just { model | now = now }

        ( Nothing, Tick now ) ->
            Update.save <|
                Just <|
                    { users =
                        UsersDb.init
                            |> UsersDb.registerUser "ADMIN" "cmt.miniBill@gmail.com" (Common.passwordHash "wololo")
                            |> Maybe.withDefault UsersDb.init
                    , now = now
                    , activeSessions = Dict.empty
                    }

        ( Nothing, _ ) ->
            ( m, Process.sleep 1001 |> Task.perform (\_ -> msg) )

        ( Just model, ClientConnected sessionId _ ) ->
            Update.map Just <|
                case Dict.get sessionId model.activeSessions of
                    Nothing ->
                        ( { model | activeSessions = Dict.remove sessionId model.activeSessions }
                        , Lamdera.sendToFrontend sessionId TFLogout
                        )

                    Just ({ playerId } as session) ->
                        if tooOld model.now session then
                            ( { model | activeSessions = Dict.remove sessionId model.activeSessions }
                            , Lamdera.sendToFrontend sessionId TFLogout
                            )

                        else
                            case UsersDb.getUserByPlayerId playerId model.users of
                                Nothing ->
                                    ( { model | activeSessions = Dict.remove sessionId model.activeSessions }
                                    , Lamdera.sendToFrontend sessionId TFLogout
                                    )

                                Just user ->
                                    ( updateLastSeen sessionId model
                                    , Lamdera.sendToFrontend sessionId <| TFLoginResult <| Ok user
                                    )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd Msg )
updateFromFrontend sessionId clientId msg m =
    case m of
        Nothing ->
            Update.save m

        Just m_ ->
            m_
                |> updateLastSeen sessionId
                |> Update.save
                |> Update.andThen
                    (\model ->
                        case msg of
                            TBLogin email passwordHash ->
                                case UsersDb.getUserByEmailAndPassowrd email passwordHash model.users of
                                    Nothing ->
                                        ( model, Lamdera.sendToFrontend clientId <| TFLoginResult (Err "Invalid username/password") )

                                    Just ( playerId, user ) ->
                                        ( { model
                                            | activeSessions =
                                                Dict.insert sessionId
                                                    { playerId = playerId
                                                    , lastSeen = model.now
                                                    }
                                                    model.activeSessions
                                          }
                                        , Lamdera.sendToFrontend sessionId <| TFLoginResult (Ok user)
                                        )

                            TBLogout ->
                                ( { model | activeSessions = Dict.remove sessionId model.activeSessions }
                                , Lamdera.sendToFrontend sessionId TFLogout
                                )

                            TBAuthenticated amsg ->
                                case Dict.get sessionId model.activeSessions of
                                    Nothing ->
                                        ( model, Lamdera.sendToFrontend sessionId TFLogout )

                                    Just { playerId } ->
                                        case UsersDb.getUserByPlayerId playerId model.users of
                                            Nothing ->
                                                ( model, Lamdera.sendToFrontend sessionId TFLogout )

                                            Just user ->
                                                updateAuthenticated playerId user amsg model
                    )
                |> Update.map Just


updateAuthenticated :
    PlayerId
    -> User
    -> TBAuthenticated
    -> InnerModel
    -> ( InnerModel, Cmd Msg )
updateAuthenticated playerId _ msg model =
    case msg of
        TBChangeNickname newNickname ->
            Update.save
                { model
                    | users =
                        UsersDb.updateUserByPlayerId playerId (\u -> { u | nickname = newNickname }) model.users
                }


updateLastSeen : SessionId -> InnerModel -> InnerModel
updateLastSeen sessionId model =
    { model
        | activeSessions =
            Dict.update sessionId
                (Maybe.andThen
                    (\session ->
                        if tooOld model.now session then
                            Nothing

                        else
                            Just { session | lastSeen = model.now }
                    )
                )
                model.activeSessions
    }


tooOld : Time.Posix -> { a | lastSeen : Time.Posix } -> Bool
tooOld now { lastSeen } =
    let
        oneDay =
            86400 * 1000
    in
    Time.posixToMillis now - Time.posixToMillis lastSeen > oneDay
