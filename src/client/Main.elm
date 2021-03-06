module TicTacToe exposing (main)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import WebSocket
import Array exposing (..)
import Json.Decode exposing (..)
import Json.Encode exposing (..)
import Debug exposing (log)

main =
    App.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

-- MODEL

type alias Board = Array (Array Move)
type alias Model =
    { name : String
    , winner: Maybe String
    , board : Board
    , host : String
    }

type alias Flags = { hostname : String }


init : Flags -> (Model, Cmd Msg)
init { hostname } =
    (Model "Your name" Nothing initBoard hostname, Cmd.none)

initBoard : Board
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

setIn : Int -> Int -> String -> Board -> Board
setIn x y name array =
    let
        row = getIn x array
        newRow = Array.set y (PlayerMoved name) row
    in
        Array.set x newRow array

getIn : Int -> Board -> Array Move
getIn x array =
    let
        row = Array.get x array
    in
        case row of
            Nothing -> Array.empty
            Just theRow -> theRow


makePlayerMove : Board -> String -> Int -> Int -> Board
makePlayerMove board name x y =
    setIn x y name board


update : Msg -> Model -> (Model, Cmd Msg)
update msg {name, winner, board, host} =
    case msg of
        InputName newInput ->
            (Model newInput winner board host, Cmd.none)
        MakeMove x y ->
            (Model name winner board host, WebSocket.send host (encodeMove name x y))
        OtherMove othername x y ->
            (Model name winner (makePlayerMove board othername x y) host, Cmd.none)
        GameWin player x y ->
            (Model name (Just player) (makePlayerMove board player x y) host, Cmd.none)
        Invalid ->
            (Model name winner board host, Cmd.none)

encodeMove : String -> Int -> Int -> String
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
      WebSocket.listen model.host decoder

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

        decoded = decodeString messageDecoder (log "message" string)
    in
        case decoded of
            Ok message -> convertMessageToType message
            Err _ -> Invalid

convertMessageToType : ServerMessage -> Msg
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
        gameBoard = Array.indexedMap createRow board
        gameBoardList = Array.foldr (Array.append) Array.empty gameBoard |> Array.toList
        winnerText = case winner of
            Nothing -> ""
            Just person -> person ++ " has Won!!!"
    in
        div []
            [ input [onInput InputName, Html.Attributes.value name] []
            , h1 [ style [("color", "red")]] [ text winnerText ]
            , div [ class "game", style [("width", "300px")]] gameBoardList
            ]

moveToText : Move -> String
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
