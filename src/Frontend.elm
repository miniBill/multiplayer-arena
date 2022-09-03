module Frontend exposing (app)

import Browser exposing (Document, UrlRequest(..))
import Browser.Dom
import Browser.Navigation as Nav exposing (Key)
import Common exposing (User)
import Element.WithContext as Element exposing (alignRight, centerX, centerY, el, fill, height, px, shrink, text, width)
import Element.WithContext.Background as Background
import Element.WithContext.Font as Font
import Element.WithContext.Input as Input
import Frontend.Common exposing (Model, Msg)
import Frontend.Homepage
import Html
import L10N exposing (Language(..))
import Lamdera
import Route exposing (AuthorizedPage(..), GamePage(..), GameRoute(..), LoginPageData, Page(..), PublicPage(..), Route(..))
import Task
import Theme exposing (Attribute, Element)
import Time
import Types exposing (..)
import Update.Pipeline as Update
import Url exposing (Url)


app :
    { init : Url -> Key -> ( Model, Cmd FrontendMsg )
    , view : Model -> Document FrontendMsg
    , update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
    , updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
    , subscriptions : Model -> Sub FrontendMsg
    , onUrlRequest : UrlRequest -> FrontendMsg
    , onUrlChange : Url -> FrontendMsg
    }
app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = view
        }


subscriptions : Model -> Sub FrontendMsg
subscriptions _ =
    Sub.none


init : Url.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init url key =
    let
        initialContext : Context
        initialContext =
            { language = English
            , tz = Time.utc
            }

        initialModel : Model
        initialModel =
            { key = key
            , context = initialContext
            , page = WaitingLoginDataFromServer <| Route.urlToRoute url
            , size = ( 800, 600 )
            }
    in
    ( initialModel
    , Cmd.batch
        [ Task.perform Timezone Time.here
        , Task.perform
            (\{ viewport } -> Size ( floor viewport.width, floor viewport.height ))
            Browser.Dom.getViewport
        ]
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key <| Url.toString url
                    )

                External url ->
                    ( model, Nav.load url )

        UrlChanged url ->
            if Route.urlToRoute url /= Route.pageToRoute model.page then
                Update.save
                    { model
                        | page =
                            toPage (Route.urlToRoute url) (getCurrentUser model.page)
                    }

            else
                Update.save model

        Timezone zone ->
            let
                context =
                    model.context
            in
            Update.save { model | context = { context | tz = zone } }

        Size size ->
            Update.save { model | size = size }

        Login email passwordHash ->
            ( model, Lamdera.sendToBackend <| TBLogin email passwordHash )

        Logout ->
            ( model, Lamdera.sendToBackend TBLogout )

        UpdatePage page ->
            Update.save { model | page = page }

        SwitchPage page ->
            ( { model | page = page }, Nav.pushUrl model.key <| Route.routeToUrl <| Route.pageToRoute page )


getCurrentUser : Page -> Maybe User
getCurrentUser page =
    case page of
        WaitingLoginDataFromServer _ ->
            Nothing

        PublicPage user _ ->
            user

        LoginPage _ ->
            Nothing

        AuthorizedPage user _ ->
            Just user


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case ( msg, model.page ) of
        ( TFLoginResult r, WaitingLoginDataFromServer route ) ->
            Update.save { model | page = toPage route <| Result.toMaybe r }

        ( TFLoginResult r, LoginPage data ) ->
            case r of
                Err e ->
                    Update.save { model | page = LoginPage { data | error = Just e } }

                Ok user ->
                    let
                        page =
                            toPage data.next <| Just user
                    in
                    { model | page = page }
                        |> Update.addCmd (Nav.replaceUrl model.key <| Route.routeToUrl <| Route.pageToRoute page)

        ( TFLogout, LoginPage _ ) ->
            Update.save model

        ( TFLogout, WaitingLoginDataFromServer route ) ->
            Update.save { model | page = toPage route Nothing }

        ( TFLogout, PublicPage _ name ) ->
            Update.save { model | page = PublicPage Nothing name }

        ( TFLoginResult (Ok user), AuthorizedPage _ data ) ->
            Update.save { model | page = AuthorizedPage user data }

        ( TFLoginResult (Err _), AuthorizedPage _ _ ) ->
            Update.save { model | page = LoginPage <| Route.initLoginPageData <| Route.pageToRoute model.page }

        ( TFLogout, AuthorizedPage _ _ ) ->
            Update.save { model | page = LoginPage <| Route.initLoginPageData <| Route.pageToRoute model.page }

        ( TFLoginResult r, PublicPage _ name ) ->
            Update.save { model | page = PublicPage (Result.toMaybe r) name }


toPage : Route -> Maybe User -> Page
toPage name user =
    case ( name, user ) of
        ( HomepageRoute, _ ) ->
            PublicPage user Homepage

        ( FourOhFourRoute, _ ) ->
            PublicPage user FourOhFour

        ( GameRoute _, Nothing ) ->
            LoginPage <| Route.initLoginPageData name

        ( GameRoute gr, Just u ) ->
            let
                toGame g =
                    case g of
                        TicTacToeLobbyRoute ->
                            TicTacToePage Nothing

                        TicTacToePlayingRoute _ ->
                            -- TODO resume game
                            TicTacToePage Nothing
            in
            AuthorizedPage u <| GamePage <| toGame gr

        ( LoginRoute, Nothing ) ->
            LoginPage <| Route.initLoginPageData HomepageRoute

        ( LoginRoute, Just _ ) ->
            PublicPage user Homepage


view : Model -> { title : String, body : List (Html.Html Msg) }
view model =
    { title = "Multiplayer Arena"
    , body =
        [ Element.layout model.context
            [ height fill
            , width fill
            , homepageElement model.page
            , loggedInElement <| getCurrentUser model.page
            ]
            (innerView model)
        ]
    }


viewError : String -> Element msg
viewError error =
    Theme.box
        [ Font.color Theme.colors.errorForeground
        , Background.color Theme.colors.errorBackground
        ]
        (text error)


viewLoginBox : LoginPageData -> Element FrontendMsg
viewLoginBox loginPageData =
    Theme.box [ centerX, centerY ] <|
        Theme.column []
            [ Element.table [ Theme.spacing ]
                { data =
                    [ ( "Email"
                      , Input.email []
                            { label = Input.labelHidden "Email"
                            , onChange = \newEmail -> { loginPageData | email = newEmail }
                            , placeholder = Just <| Input.placeholder [] <| text "your@email.tld"
                            , text = loginPageData.email
                            }
                      )
                    , ( "Password"
                      , Input.currentPassword []
                            { label = Input.labelHidden "Password"
                            , onChange = \newPassword -> { loginPageData | password = newPassword }
                            , placeholder = Just <| Input.placeholder [] <| text "Password"
                            , show = False
                            , text = loginPageData.password
                            }
                      )
                    ]
                , columns =
                    [ { header = Element.none
                      , width = shrink
                      , view = \( label, _ ) -> el [ centerY ] <| text label
                      }
                    , { header = Element.none
                      , width = px 200
                      , view =
                            \( _, input ) -> Element.map (UpdatePage << LoginPage) input
                      }
                    ]
                }
            , Input.button [ alignRight ]
                { onPress = Just <| Login loginPageData.email <| Common.passwordHash loginPageData.password
                , label = Theme.box [] <| text "Login"
                }
            ]


innerView : Model -> Element Msg
innerView { page } =
    case page of
        WaitingLoginDataFromServer _ ->
            el [ centerX, centerY, Font.size Theme.fontSizes.huge ] <|
                text "Checking login..."

        PublicPage maybeUser Homepage ->
            Frontend.Homepage.view maybeUser

        PublicPage _ FourOhFour ->
            viewFourOhFour

        LoginPage data ->
            viewLoginBox data

        AuthorizedPage _ (GamePage game) ->
            case game of
                TicTacToePage Nothing ->
                    el [ centerX, centerY, Font.size Theme.fontSizes.huge ] <|
                        text "Tic Tac Toe lobby [TODO]"

                TicTacToePage (Just _) ->
                    text "TODO"


viewFourOhFour : Element Msg
viewFourOhFour =
    el
        [ centerX
        , centerY
        , Font.size Theme.fontSizes.huge
        ]
        (text "Page not found :(")


homepageElement : Page -> Attribute msg
homepageElement page =
    Element.inFront <|
        case page of
            PublicPage _ Homepage ->
                Element.none

            WaitingLoginDataFromServer HomepageRoute ->
                Element.none

            _ ->
                Theme.link [ Theme.padding ]
                    { label = text "Homepage"
                    , url = Route.routeToUrl HomepageRoute
                    }


loggedInElement : Maybe User -> Attribute Msg
loggedInElement maybeUser =
    Element.inFront <|
        case maybeUser of
            Nothing ->
                Element.none

            Just { nickname, email } ->
                Theme.row [ alignRight, Theme.padding ] <|
                    [ text <| "Logged in as " ++ nickname ++ " (" ++ email ++ ")"
                    , Input.button []
                        { label = Theme.box [] <| text "Logout"
                        , onPress = Just Logout
                        }
                    ]
