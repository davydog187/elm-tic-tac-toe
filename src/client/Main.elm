import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import WebSocket
import Array exposing (..)
import Json.Decode exposing (..)
import Json.Encode exposing (..)

main =
    App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

ticTacToeServer : String
ticTacToeServer =
      "ws://localhost:8080"


-- MODEL


type alias Model =
    { name : String
    , winner: Maybe String
    , board : Array (Array Move)
    }


init : (Model, Cmd Msg)
init =
    (Model "Your name" Nothing initBoard, Cmd.none)

initBoard =
    Array.repeat 3 (Array.repeat 3 None)


-- UPDATE

type Move
    = None
    | PlayerMoved String


type Msg
    = InputName String
    | OtherMove String Int Int
    | MakeMove Int Int
    | GameWin String Int Int
    | Invalid

setIn x y name array =
    let
        row = getIn x array
        newRow = Array.set y (PlayerMoved name) row
    in
        Array.set x newRow array

getIn x array =
    let
        row = Array.get x array
    in
        case row of
            Nothing -> Array.empty
            Just theRow -> theRow


makePlayerMove board name x y =
    setIn x y name board


update : Msg -> Model -> (Model, Cmd Msg)
update msg {name, winner, board} =
    case msg of
        InputName newInput ->
            (Model newInput winner board, Cmd.none)
        MakeMove x y ->
            (Model name winner board, WebSocket.send ticTacToeServer (encodeMove name x y))
        OtherMove othername x y ->
            (Model name winner (makePlayerMove board othername x y), Cmd.none)
        GameWin player x y ->
            (Model name (Just player) (makePlayerMove board player x y), Cmd.none)
        Invalid ->
            (Model name winner board, Cmd.none)


encodeMove name x y =
    let
        msg =
            Json.Encode.object
                [ ("msgType", Json.Encode.string "MOVE")
                , ("player", Json.Encode.string name)
                , ("x", Json.Encode.int x)
                , ("y", Json.Encode.int y)
                ]
    in
        encode 0 msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
      WebSocket.listen ticTacToeServer decoder

type alias ServerMessage = { x : Int, y : Int, msgType : String, player : String }

messageDecoder =
    object4 ServerMessage
        ("x" := Json.Decode.int)
        ("y" := Json.Decode.int)
        ("msgType" := Json.Decode.string)
        ("player" := Json.Decode.string)


decoder : String -> Msg
decoder string =
    let
        decoded = decodeString messageDecoder string
    in
        case decoded of
            Ok message -> convertMessageToType message
            Err _ -> Invalid

convertMessageToType { msgType, x, y, player } =
        case msgType of
            "MOVED" -> OtherMove player x y
            "WIN" -> GameWin player x y
            _ -> Invalid


-- VIEW


view : Model -> Html Msg
view { name, winner, board } =
    let
        createRow index = Array.indexedMap (\col square -> (viewSquare square index col))
        gameBoard = Array.indexedMap (\row list -> createRow row list) board
        combined = Array.foldr (Array.append) Array.empty gameBoard
        winnerText = case winner of
            Nothing -> ""
            Just person -> person ++ " has Won!!!"
    in
        div []
            [ input [onInput InputName, Html.Attributes.value name] []
            , h1 [ style [("color", "red")]] [ text winnerText ]
            , div [ class "game", style [("width", "300px")]] (Array.toList combined)
            ]


moveToText move =
    case move of
        None -> ""
        PlayerMoved player -> player

viewSquare : Move -> Int -> Int -> Html Msg
viewSquare move x y =
    let
        buttonStyle =
            style
                [ ("height", "100px")
                , ("width", "100px")
                , ("vertical-align", "top")
                ]
    in
        button [onClick (MakeMove x y), buttonStyle] [ text (moveToText move) ]

viewMessage : String -> Html Msg
viewMessage msg =
      div [] [ text msg ]
