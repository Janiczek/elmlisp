module Counter exposing (..)

import Html exposing (Html, div, text, button)

import Html.Attributes exposing (onClick)

main : Program Never Model Msg
main =
    Html.beginnerProgram { model = model, update = update, view = view }

type alias Model =
    Int

type Msg
    = Inc
    | Dec

update : Msg -> Model -> Model
update msg model =
    case msg of
        Inc ->
            1 + model

        Dec ->
            1 - model

view : Model -> Html Msg
view model =
    div [] [ button [ onClick Dec ] [ text "-1" ], text toString model, button [ onClick Inc ] [ text "+1" ] ]

