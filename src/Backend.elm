module Backend exposing (..)

import Dict
import Lamdera exposing (ClientId, SessionId)
import Process
import Task
import Time
import Types exposing (..)
import Update.Pipeline as Update


type alias Model =
    BackendModel


type alias InnerModel =
    InnerBackendModel


app :
    { init : ( Model, Cmd BackendMsg )
    , update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
    , updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
    , subscriptions : Model -> Sub BackendMsg
    }
app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ Lamdera.onConnect ClientConnected
        , Time.every 10000 Tick
        ]


init : ( Model, Cmd BackendMsg )
init =
    Update.save Nothing


superAdmin : ( User, PasswordHash )
superAdmin =
    ( superAdminUser, Types.passwordHash "wololo" )


superAdminUser : User
superAdminUser =
    { email = "cmt.miniBill@gmail.com"
    , isAdmin = True
    , nickname = "miniBill"
    }


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg m =
    case ( m, msg ) of
        ( Just model, Tick now ) ->
            Update.save <| Just { model | now = now }

        ( Nothing, Tick now ) ->
            Update.save <|
                Just <|
                    { users =
                        Types.initUserDb
                            |> Types.registerUser "ADMIN" "cmt.miniBill@gmail.com" (Types.passwordHash "wololo")
                            |> Maybe.withDefault Types.initUserDb
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
                            case Types.getUserByPlayerId playerId model.users of
                                Nothing ->
                                    ( { model | activeSessions = Dict.remove sessionId model.activeSessions }
                                    , Lamdera.sendToFrontend sessionId TFLogout
                                    )

                                Just user ->
                                    ( updateLastSeen sessionId model
                                    , Lamdera.sendToFrontend sessionId <| TFLoginResult <| Ok user
                                    )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
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
                                case Types.getUserByEmailAndPassowrd email passwordHash model.users of
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
                                        case Types.getUserByPlayerId playerId model.users of
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
    -> ( InnerModel, Cmd BackendMsg )
updateAuthenticated playerId _ msg model =
    case msg of
        TBChangeNickname newNickname ->
            Update.save
                { model
                    | users =
                        Types.updateUserByPlayerId playerId (\u -> { u | nickname = newNickname }) model.users
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
