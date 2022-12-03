module Frontend exposing (app)

import Browser exposing (Document, UrlRequest(..))
import Browser.Dom
import Browser.Navigation as Nav exposing (Key)
import Element.WithContext as Element exposing (alignRight, centerX, centerY, el, fill, height, px, shrink, text, width)
import Element.WithContext.Background as Background
import Element.WithContext.Font as Font
import Element.WithContext.Input as Input
import Frontend.Homepage
import Html
import Lamdera
import Route exposing (GamePage(..), GameRoute(..), Page(..), Route(..))
import Task
import Theme exposing (Attribute, Element)
import Time
import Translations exposing (Language(..))
import Types exposing (..)
import Types.GameId as GameId
import Update.Pipeline as Update
import Url exposing (Url)


app :
    { init : Url -> Key -> ( FrontendModel, Cmd FrontendMsg )
    , view : FrontendModel -> Document FrontendMsg
    , update : FrontendMsg -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
    , updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
    , subscriptions : FrontendModel -> Sub FrontendMsg
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


subscriptions : FrontendModel -> Sub FrontendMsg
subscriptions _ =
    Sub.none


init : Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
init url key =
    let
        initialContext : Context
        initialContext =
            { i18n = Translations.init En
            , tz = Time.utc
            }

        initialModel : FrontendModel
        initialModel =
            { key = key
            , context = initialContext
            , page = toPage <| Route.urlToRoute url
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


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
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
                            toPage (Route.urlToRoute url)
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

        UpdatePage page ->
            Update.save { model | page = page }


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        TFNop ->
            Update.save model


toPage : Route -> Page
toPage name =
    case name of
        HomepageRoute ->
            Homepage

        FourOhFourRoute ->
            FourOhFour

        GameRoute gr ->
            let
                toGame g =
                    case g of
                        TicTacToeLobbyRoute ->
                            TicTacToePage Nothing

                        TicTacToePlayingRoute _ ->
                            -- TODO resume game
                            TicTacToePage Nothing
            in
            GamePage <| toGame gr


view : FrontendModel -> { title : String, body : List (Html.Html FrontendMsg) }
view model =
    { title = "Multiplayer Arena"
    , body =
        [ Element.layout model.context
            [ height fill
            , width fill
            , homepageElement model.page
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


innerView : FrontendModel -> Element FrontendMsg
innerView { page } =
    case page of
        Homepage ->
            Frontend.Homepage.view

        FourOhFour ->
            viewFourOhFour

        GamePage game ->
            case game of
                TicTacToeJoiningPage gameId ->
                    el [ centerX, centerY, Font.size Theme.fontSizes.huge ] <|
                        Theme.text (Translations.joiningGame (GameId.toString gameId))

                TicTacToeLobbyPage _ ->
                    text "branch 'TicTacToeLobbyPage _' not implemented"

                TicTacToePlayingPage _ ->
                    text "branch 'TicTacToePlayingPage _' not implemented"


viewFourOhFour : Element FrontendMsg
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
            Homepage ->
                Element.none

            _ ->
                Theme.link [ Theme.padding ]
                    { label = text "Homepage"
                    , route = HomepageRoute
                    }
