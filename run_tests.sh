#!/usr/bin/env bash

COLOR_OFF="\e[0m";
DIM="\e[2m";

function redraw_and_run {
  clear;

  echo -en "${DIM}";
  date -R;
  echo -en "${COLOR_OFF}";

  racket test_runner.rkt;
}

redraw_and_run;

while inotifywait -qqre modify ./tests ./src; do
  redraw_and_run;
done;

